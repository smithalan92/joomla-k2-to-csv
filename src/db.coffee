mysql    = require 'promise-mysql'
squel    = require 'squel'
dbConfig = require './dbconfig'
Promise  = require 'bluebird'

class DatabaseHelper

    conn: null

    openConnection: ->
        Promise.resolve() if @conn
        return mysql.createConnection dbConfig.login
        .then (_conn) =>
            @conn = _conn

    closeConnection: ->
        return Promise.reject() unless @conn
        @conn.destroy()

    runQuery: ({text, values}) ->
        return @conn.query text, values

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