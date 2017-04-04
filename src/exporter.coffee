db      = require './db'
Promise = require 'bluebird'
csv     = require 'fast-csv'
fs      = require 'fs'
crypto  = require 'crypto'
config  = require './dbconfig'
moment  = require 'moment'

class Importer

    # Entry point to kick off the whole exporting process
    processItems: ->
        # Create a  csv writestream, create a fs writesteam
        @csvStream = csv.createWriteStream {headers: true}
        fileName = "WCExport-#{moment().format("DD-MM-YYYY-HHmmss")}.csv"
        writeableStream = fs.createWriteStream(fileName)
        # Pipe our csv stream to the fs stream
        @csvStream.pipe writeableStream
        # Open a DB connection
        return db.openConnection()
        .then ->
            # Get number of items to export
            return db.getTotalItemCount()
        .then (count) ->
            console.log "[#{moment().format("HH:mm:ss")}]: Readying export of #{count} items to a CSV"
            # Get the highest item ID (for paging queries)
            return db.getHighestItemID()
        .then (max) =>
            console.log "[#{moment().format("HH:mm:ss")}]: Starting Export..........."
            # Get the items and process them
            return @getItems 0, 25, max
        .then =>
            # Close the stream and db connection
            @csvStream.end()
            db.closeConnection()
            console.log "[#{moment().format("HH:mm:ss")}]: Export completed to file #{fileName}"



    # Gets a max of 25 items from the db at a time
    # recursively calls itself
    # fromId - {Number} ID to page from
    # toID - {Number} ID to page to
    # Returns a {Promise}
    getItems: (fromID, toID, maxID) ->
        return Promise.resolve() if fromID > maxID
        console.log "Getting any items with IDs between #{fromID} and #{toID} from Database"
        return db.getItemsInIDRange fromID, toID
        .then (res) =>
            console.log "Writing any items with IDs between #{fromID} and #{toID} to CSV"
            return @writeToCSV res
        .then =>
            return @getItems fromID + 25, toID + 25, maxID

    # Writes an array of item objects to a CSV file
    # items - {Array}
    writeToCSV: (items) ->
        items.forEach (item) =>
            @csvStream.write item



module.exports = new Importer()