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
	saved_pics = params[:pic_choice]
	saved_tag = params[:tag]
	saved_pics.each do |pic|
		db.execute("insert into pics (tag, img_url) values (?, ?);", saved_tag, pic)
	end
	redirect("/")
end

post "/results" do
	url_arr=[]
	content = JSON.load File.new("./public/secrets.json")
	new_tag = params[:new_tag]	
	url = "https://api.instagram.com/v1/tags/" + new_tag + "/media/recent?client_id=" + content["insta_cli_id"];
	puts url
	response = HTTParty.get(url)
	image_path = response["data"]
	count=0
	image_path.each do |pic|
		count += 1
		url_arr.push(pic["images"]["low_resolution"]["url"])
		break if count >= 10
	end
	erb :show, locals: { pics_arr: url_arr, tag: new_tag }
end



