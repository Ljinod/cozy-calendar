cozydb = require 'cozydb'

module.exports = Contact = cozydb.getModel 'Contact',
    fn            : String
    n             : String
    datapoints    : [Object]
    _attachments  : Object


Contact::asNameAndEmails = ->
    name = @fn or @n?.split(';')[0..1].join ' '
    emails = @datapoints?.filter (dp) -> dp.name is 'email'

    # XXX What if several Cozy instances are linked to one user?
    cozy = dp.value for dp in @datapoints when dp.name is 'other' and dp.type is 'COZY'

    return simple =
        id: @id
        name: name or '?'
        emails: emails or []
        hasPicture: @_attachments?.picture?
        # The function filter returns an array and since, in our test case,
        # there is only one cozy linked to a contact we can safely access the
        # first element of the array
        cozy: cozy or '?'
