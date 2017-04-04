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
            SELECT COUNT(id) as count
            FROM #{dbConfig.wcItemsTable}
            WHERE post_status = 'publish'
            AND post_type IN ('product', 'variable_product')
            """

        return @runQuery {text: query}
        .then (res) ->
            throw new Error("No result") unless res.length
            return res[0].count

    # Gets a count of items to export
    # only includes published items
    # Returns a {Promise} that resolves to an {Object} or throws an error
    getHighestItemID: ->
        query = """
            SELECT MAX(id)
            FROM #{dbConfig.wcItemsTable}
            WHERE post_status = 'publish'
            AND post_type IN ('product', 'variable_product')
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
            .from dbConfig.wcItemsTable, "p"
            .field 'p.ID'
            .field 'p.post_title AS name'
            .field 'p.post_content AS full_description'
            .field 'p.post_excerpt AS short_description'
            .field 'pm1.meta_value AS price'
            .field 'pm3.meta_value AS sku'
            .field 'p2.guid AS image'
            .left_join dbConfig.wcMetadataTable, 'pm1', "p.ID = pm1.post_id AND pm1.meta_key = '_regular_price'"
            .left_join dbConfig.wcMetadataTable, 'pm2', "p.ID = pm2.post_id AND pm2.meta_key = '_thumbnail_id'"
            .left_join dbConfig.wcMetadataTable, 'pm3', "p.ID = pm3.post_id AND pm3.meta_key = '_sku'"
            .left_join dbConfig.wcItemsTable, 'p2', "p2.ID = pm2.meta_value"
            .where "p.id >= ?", min
            .where "p.id <= ?", max
            .where "p.post_status = ?", "publish"
            .where "p.post_type IN ?", ['product', 'variable_product']

        return @runQuery expression.toParam()
        .then (res) ->
            return res

module.exports = new DatabaseHelper()