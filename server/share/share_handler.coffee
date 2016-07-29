cozydb    = require 'cozydb'

# Polyfill to provide the function `find` if it is not already implemented
# See : https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/
#                   Global_Objects/Array/find
unless Array.prototype.find
    Array.prototype.find = (predicate) ->
        if this is null
            throw new TypeError "Find call on null or undefined."

        if (typeof predicate) isnt "function"
            throw new TypeError "Predicate must be a function."

        list    = Object this
        length  = list.length >>> 0
        thisArg = arguments[1]
        i       = 0
        value   = list[i]

        while value
            if predicate.call thisArg, value, i, list
                return value
            value = list[++i]

        return undefined


module.exports.sendShareInvitations = (event, callback) ->
    guests     = event.toJSON().attendees
    needSaving = false

    # Before proceeding any further we check here that we have to share the
    # event with at least one guest.
    hasGuestToShare = guests.find (guest) ->
        return (guest.isSharedWithCozy and
               (guest.status is 'INVITATION-NOT-SENT'))

    # If we haven't found a single guest to share the event with, we stop here.
    unless hasGuestToShare
        return callback()

    # The format of the req.body to send must match:
    #
    # desc      : the sharing description
    # rules     : [{docType: "event", id: id_of_the_event}]
    # targets   : [
    #   {recipientUrl: guest-1-url-cozy},
    #   {recipientUrl: guest-2-url-cozy}, ...
    # ]
    # continuous: true
    data =
        desc       : event.description
        rules      : [{id: event.id, docType: 'event'}]
        targets    : []
        continuous : true

    # only process relevant guests
    guests.forEach (guest) ->
        if (guest.status is 'INVITATION-NOT-SENT') and guest.isSharedWithCozy
            data.targets.push recipientUrl: guest.cozy
            guest.status = "NEEDS-ACTION"
            needSaving   = true

    # Send the request to the datasystem
    cozydb.api.createSharing data, (err, body) ->
        if err?
            callback err
        else unless needSaving
            callback()
        else
            event.updateAttributes attendees: guests, callback


module.exports.cancelShare = (event, callback) ->

    # We only need to do something if the event is shared.
    if event.shareID
        # To know which function we have to call we need to check if a sharing
        # document with an id equal to that of the `shareID` of the event
        # exists. If that is the case then the owner shared the event (the owner
        # is the "sharer"), if not then someone else shared it (the owner is the
        # "recipient").
        Sharing.exists event.shareID, (err, exists) ->
            if exists
                # The owner shared the event.
                cozydb.api.revokeSharingFromSharer event.shareID, (err, body) ->
                    if err?
                        return callback err
                    else
                        return callback()
            else
                # The event was shared to the owner. We need to fetch the
                # "sharing" document that is linked to the shareID.
                Sharing.request 'byShareID', key: event.shareID,
                (err, docSharing) ->
                    cozydb.api.revokeSharingFromRecipient docSharing[0]._id,
                    (err, body) ->
                        if err?
                            return callback err
                        else
                            return callback()

    # The event was not shared, we don't have a thing to do.
    else
        return callback()

