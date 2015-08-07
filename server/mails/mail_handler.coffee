async = require 'async'
fs    = require 'fs'
jade  = require 'jade'
os    = require 'os'
path  = require 'path'
log   = require('printit')
    prefix: 'MailHandler'
    date: true

cozydb = require 'cozydb'
Event = require '../models/event'
User  = require '../models/user'

{VCalendar} = require 'cozy-ical'


localization = require '../libs/localization_manager'

module.exports.sendInvitations = (event, dateChanged, callback) ->
    guests = event.toJSON().attendees
    needSaving = false

    async.parallel [
        (cb) -> cozydb.api.getCozyDomain cb
        (cb) -> User.getUserInfos cb
    ], (err, results) ->
        return callback err if err

        [domain, user] = results

        async.forEach guests, (guest, done) ->

            # only process relevant guests, quits otherwise
            shouldSend = guest.status is 'INVITATION-NOT-SENT' or \
                        (guest.status is 'ACCEPTED' and dateChanged)
            return done() unless shouldSend

            # Prepare mail
            if dateChanged
                htmlTemplate = localization.getEmailTemplate 'mail_update'
                subjectKey   = 'email update title'
                templateKey  = 'email update content'
            else
                htmlTemplate = localization.getEmailTemplate 'mail_invitation'
                subjectKey   = 'email invitation title'
                templateKey  = 'email invitation content'

            # Get mail contents
            subject = localization.t subjectKey, description: event.description
            url     = "#{domain}public/calendar/events/#{event.id}"

            date          = event.formatStart dateFormat
            dateFormat    = localization.t dateFormatKey
            dateFormatKey = if event.isAllDayEvent()
                'email date format allday'
            else
                'email date format'

            {description, place} = event.toJSON()
            place = if place?.length > 0 then place else ""

            # Build mails
            templateOptions =
                displayName:  user.name
                displayEmail: user.email
                description:  description
                place:        place
                key:          guest.key
                date:         date
                url:          url

            mailOptions =
                to:      guest.email
                subject: subject
                html:    htmlTemplate templateOptions
                content: localization.t templateKey, templateOptions

            # Attach event as ics file
            calendarOptions =
                organization:'Cozy Cloud'
                title: 'Cozy Calendar'
            calendar = new VCalendar calendarOptions
            calendar.add event.toIcal()
            icsPath = path.join os.tmpdir(), 'invite.ics'
            fs.writeFile icsPath, calendar.toString(), (err) ->
                if (err)
                    log.error """
                      An error occured while creating invitation file #{icsPath}
                    """
                    log.error err
                else
                    mailOptions.attachments = [
                        contentType: 'text/calendar'
                        path: icsPath
                    ]

                # Send mail through CozyDB API
                cozydb.api.sendMailFromUser mailOptions, (err) ->
                    if err
                        log.error "An error occured while sending invitation"
                        log.error err
                    else
                        needSaving   = true
                        guest.status = 'NEEDS-ACTION' # ical = waiting an answer

                    fs.unlink icsPath, (errUnlink) ->
                        if errUnlink
                            log.error "Error deleting ics file #{icsPath}"
                        done err

        # Catch errors when doing async foreach
        , (err) ->
            if err?
                callback err
            else unless needSaving
                callback()
            else
                event.updateAttributes attendees: guests, callback


module.exports.sendDeleteNotification = (event, callback) ->
    guests = event.toJSON().attendees
    # only process guests that have accepted to attend the event
    guestsToInform = guests.filter (guest) ->
        return guest.status in ['ACCEPTED', 'NEEDS-ACTION']

    User.getUserInfos (err, user) ->
        return callback err if err

        async.eachSeries guestsToInform, (guest, done) ->

            if event.isAllDayEvent()
                dateFormatKey = 'email date format allday'
            else
                dateFormatKey = 'email date format'
            dateFormat = localization.t dateFormatKey
            date = event.formatStart dateFormat
            {description, place} = event.toJSON()
            place = if place?.length > 0 then place else false
            templateOptions =
                displayName: user.name
                displayEmail: user.email
                description: description
                place: place
                date: date
            htmlTemplate = localization.getEmailTemplate 'mail_delete'
            subjectKey = 'email delete title'
            subject = localization.t subjectKey, description: event.description
            mailOptions =
                to: guest.email
                subject: subject
                content: localization.t 'email delete content', templateOptions
                html: htmlTemplate templateOptions
            cozydb.api.sendMailFromUser mailOptions, (err) ->
                if err?
                    log.error "An error occured while sending email"
                    log.error err

                done err

        , callback
