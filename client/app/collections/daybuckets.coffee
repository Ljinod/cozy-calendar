ScheduleItemsCollection = require './scheduleitems'

DayBucket = class DayBucket extends Backbone.Model
    constructor: (model) ->
        console.log model, new Error().stack if not model.getDateHash
        super
            id: model.getDateHash()
            date: model.getDateObject().clone().beginningOfDay()
    initialize: ->
        @items = new ScheduleItemsCollection()


module.exports = class DayBucketCollection extends Backbone.Collection

    model: DayBucket
    comparator: (db1, db2) ->
        d1 = Date.create db1.get('date')
        d2 = Date.create db2.get('date')
        if d1 < d2 then return -1
        else if d1 > d2 then return 1
        else return 0

    initialize: ->
        @alarmCollection = app.alarms
        @eventCollection = app.events

        @listenTo @alarmCollection, 'add', @onBaseCollectionAdd
        @listenTo @alarmCollection, 'change:trigg', @onBaseCollectionChange
        @listenTo @alarmCollection, 'remove', @onBaseCollectionRemove
        @listenTo @alarmCollection, 'reset', @resetFromBase

        @listenTo @eventCollection, 'add', @onBaseCollectionAdd
        @listenTo @eventCollection, 'change:start', @onBaseCollectionChange
        @listenTo @eventCollection, 'remove', @onBaseCollectionRemove
        @listenTo @eventCollection, 'reset', @resetFromBase

        @resetFromBase()

    resetFromBase: ->
        @reset []
        @alarmCollection.each (model) => @onBaseCollectionAdd model
        @eventCollection.each (model) => @onBaseCollectionAdd model

    onBaseCollectionChange: (model) ->
        old = @get model.getPreviousDateHash()
        bucket = @get model.getDateHash()
        return if old is bucket
        old.items.remove model
        @remove old if old.items.length is 0
        @add(bucket = new DayBucket model) unless bucket
        bucket.items.add model

    onBaseCollectionAdd: (model) ->
        bucket = @get model.getDateHash()
        @add(bucket = new DayBucket model) unless bucket
        bucket.items.add model

    onBaseCollectionRemove: (model) ->
        bucket = @get model.getDateHash()
        bucket.items.remove model
        @remove bucket if bucket.items.length is 0
