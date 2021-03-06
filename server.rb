require 'sinatra'
require 'sqlite3'
require 'httparty'
require 'json'

db = SQLite3::Database.new "pap.db"

rows = db.execute <<-SQL
	create table if not exists pics (
		id integer PRIMARY KEY,
		tag TEXT,
		img_url TEXT
		);
SQL

# renders the search page with any saved pictures
get "/" do
	pic_list = db.execute("select * from pics;")
	erb :pap, locals: {pics: pic_list}
end

# posts all chosen pics from results page
post "/" do 
	saved_pics = params[:pic_choice]
	saved_tag = params[:tag]
	saved_pics.each do |pic|
		db.execute("insert into pics (tag, img_url) values (?, ?);", saved_tag, pic)
	end
	redirect("/")
end

# post results from instagram tag search to show page
post "/results" do
	url_arr=[]
	content = JSON.load File.new("./public/secrets.json")
	new_tag = params[:new_tag].gsub(/\s/,"")
	location= params[:location]

	# if the location checkbox is chosen, do this
	if (location)
		gquery = "https://maps.googleapis.com/maps/api/geocode/json?address=" << new_tag
		g_response = HTTParty.get(gquery)

		lat = g_response["results"][0]["geometry"]["location"]["lat"]
		lng = g_response["results"][0]["geometry"]["location"]["lng"]

		wquery ="http://api.wunderground.com/api/93df331295e1726f/conditions/q/" + lat.to_s + "," + lng.to_s + ".json"
		w_response = HTTParty.get(wquery)

		if (w_response["current_observation"])
			w_image = w_response["current_observation"]["icon_url"]
		end

		url = "https://api.instagram.com/v1/media/search?lat=" << lat.to_s << "&lng=" <<lng.to_s << "&client_id=" << content["insta_cli_id"]

	# searching by tag
	else
		url = "https://api.instagram.com/v1/tags/" + new_tag + "/media/recent?client_id=" + content["insta_cli_id"]
	end

	# runs the instagram query
	response = HTTParty.get(url)
	image_path = response["data"]
	count=0
	image_path.each do |pic|
		count += 1
		url_arr.push(pic["images"]["low_resolution"]["url"])
		break if count >= 10
	end

	w_image = "" if !w_image
		erb :show, locals: { pics_arr: url_arr, tag: new_tag, w_image: w_image }
end

# deletes a saved photo from the db
delete "/" do
	id=params[:pic_id].to_i
	db.execute("delete from pics where id = ?;", id)
	redirect("/")
end

