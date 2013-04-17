Alarm = define 'alarm', ->

    property 'action', String, default: 'DISPLAY'
    property 'trigg', String
    property 'description', String

    # Further work to make the doctype iCal compliant
    # email properties
    #property 'summary', String, default: null
    #property 'attendee', String, default: null

    # display properties
    #property 'duration', String
    #property 'repeat', String

    ### Constraints an alarm of alarms
        * All types
            action{1} : in [AUDIO, DISPLAY, EMAIL, PROCEDURE]
            trigger{1} : when the alarm is triggered


        * Display
            description{1} : text to display when alarm is triggered
            (
                duration
                repeat
            )?

        * Email
            summary{1} : email title
            description{1} : email content
            attendee+ : email addresses the message should be sent to
            attach* : message attachments

        * Audio
            (
                duration
                repeat
            )?

            attach? : sound resource (base-64 encoded binary or URL)

        * Proc
            attach{1} : procedure resource to be invoked
            (
                duration
                repeat
            )?
            description?
    ###

    ###

    # Reminder - Compliant with iCal 'VTodo'
    # http://tools.ietf.org/html/rfc2445 p54

    # must not occur more than once, optional
    property 'class', String, default: "PRIVATE" # p78
    property 'completed', String, default: null
    property 'created', String, default: null
    property 'description', String, default: null # p80
    property 'dtstamp', String, default: null
    property 'dtstart', String, default: null
    property 'geo', String, default: null # p 81
    property 'last-mod', String, default: null
    property 'location', String, default: null
    property 'organizer', String, default: null
    property 'percent', String, default: null
    property 'priority', String, default: null
    property 'recurid', String, default: null
    property 'seq', String, default: null
    property 'status', String, default: null
    property 'summary', String, default: null
    property 'uid', String, default: null
    property 'url', String, default: null


    # Those two can't occur in the same object
    property 'due', String, default: null # p91
    property 'duration', String, default: null

    # may occur more than once, optional
    property 'attach', String, default: null # p76
    property 'attendee', String, default: null
    property 'categories', String, default: null # p77
    property 'comment', String, default: null # p79
    property 'contact', String, default: null
    property 'exdate', String, default: null
    property 'exrule', String, default: null
    property 'rstatus', String, default: null
    property 'related', String, default: null
    property 'resources', String, default: null
    property 'rdate', String, default: null
    property 'rrule', String, default: null
    # VAlarm - Compliant with iCal - http://tools.ietf.org/html/rfc2445 p67
    property 'alarms', String, default : null
    ###