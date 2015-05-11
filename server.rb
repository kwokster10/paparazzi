require 'sinatra'
require 'sqlite3'
require 'httparty'
# require './public/secrets.json'
require 'json'

db = SQLite3::Database.new "pap.db"

rows = db.execute <<-SQL
	create table if not exists pics (
		id integer PRIMARY KEY,
		tag TEXT,
		img_url TEXT
		);
SQL

get "/" do
	pic_list = db.execute("select * from pics;")
	erb :pap, locals: {pics: pic_list}
end

post "/" do
	content = JSON.load File.new("./public/secrets.json")
	
	new_tag = params[:new_tag]
	
	url = "https://api.instagram.com/v1/tags/" + new_tag + "/media/recent?client_id=" + content["insta_cli_id"];
	puts url
	response = HTTParty.get(url)
	
	puts response
end



