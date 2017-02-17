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
        fileName = "K2Export-#{moment().format("DD-MM-YYYY-HHmmss")}.csv"
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
        return db.getItemsInIDRange fromID, toID
        .then (res) =>
            return @processResults res
        .then (res) =>
            return @writeToCSV res
        .then =>
            return @getItems fromID + 25, toID + 25, maxID

    # Processes results retried from the database. Sets the category
    # and image URL of each result propery
    # Returns an {Array}
    processResults: (results) ->
        results.forEach (res) =>
            res.category = "Products|Products->#{res.catName}"
            delete res["catName"]
            res.image = @getImageUrl res.id

        return results

    # Generates the URL of the image for an Item
    # itemID - The ID of the Item
    # Returns a {String}
    getImageUrl: (itemID) ->
        # K2 names images by generating a MD5 hash of Image{ItemID}
        hash = crypto.createHash('md5').update("Image#{itemID}").digest("hex");

        return "#{config.baseImgURL}#{hash}_#{config.baseImgSize}#{config.imgExtension}"

    # Writes an array of item objects to a CSV file
    # items - {Array}
    writeToCSV: (items) ->
        items.forEach (item) =>
            @csvStream.write item



module.exports = new Importer()