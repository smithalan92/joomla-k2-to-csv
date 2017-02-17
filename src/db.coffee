mysql    = require 'promise-mysql'
squel    = require 'squel'
dbConfig = require './dbconfig'
Promise  = require 'bluebird'

# Helper class for database functions
class DatabaseHelper

    conn: null

    # Opens a connection to the database
    # Returns a Promise
    openConnection: ->
        Promise.resolve() if @conn
        return mysql.createConnection dbConfig.login
        .then (_conn) =>
            @conn = _conn

    # Destroys a open db connection
    closeConnection: ->
        return unless @conn
        @conn.destroy()

    # Excecutes a database query
    # text - {String}
    # values - {Array}
    # Returns a {Promise}
    runQuery: ({text, values}) ->
        return @conn.query text, values

    # Gets a count of items to export
    # only includes published items
    # Returns a {Promise} that resolves to an {Object} or throws an error
    getTotalItemCount: ->
        query = """
            SELECT COUNT(id)
            FROM #{dbConfig.k2ItemsTable}
            WHERE published = 1
            """

        return @runQuery {text: query}
        .then (res) ->
            throw new Error("No result") unless res.length
            return res[0]["COUNT(id)"]

    # Gets a count of items to export
    # only includes published items
    # Returns a {Promise} that resolves to an {Object} or throws an error
    getHighestItemID: ->
        query = """
            SELECT MAX(id)
            FROM #{dbConfig.k2ItemsTable}
            WHERE published = 1
            """

        return @runQuery {text: query}
        .then (res) ->
            throw new Error("No result") unless res.length
            return res[0]["MAX(id)"]

    # Gets items in with a certain ID range
    # min - {Number} - Min ID 
    # max - {Number} - Max ID
    # Returns a {Promise} that resolves to an {Array} of {Objects}
    getItemsInIDRange: (min, max) ->
        expression = squel.select()
            .from dbConfig.k2ItemsTable, "k2Items"
            .field 'k2Items.id'
            .field 'k2Items.title AS product_title'
            .field 'k2Items.introtext as product_desc'
            .field 'k2Cats.name AS catName' 
            .where 'k2Items.id BETWEEN ? and ?', min, max
            .where 'k2Items.published = 1'
            .right_join dbConfig.k2CatTable, "k2Cats", "k2Cats.id = k2Items.catID" 

        return @runQuery expression.toParam()

module.exports = new DatabaseHelper()