# heel simpele webapp om sinatra met een database te laten werken 
require 'sinatra'
require 'data_mapper'

# Nu een in-memory Sqlite3 db, kan natuurlijk makkelijk een permanentere database worden
DataMapper.setup(:default, 'sqlite:tinyboard.sqlite')

#een class voor posts 
class Post
  include DataMapper::Resource
  #database columns:
  property :id,            Serial    # An auto-increment integer key
  property :username,      String    # IP adress van de visitor.
  property :time_of_post,  DateTime  # Een DateTime, time of posting
  property :post_contents, String    # Wat de gebruiker wil posten. 
  
  #dit zou waarschijnlijk beter kunnen met een mooie templating language, maar dat is een ander probeersel
  def show
    "<div style=\"width:100%\"><h3>" + 
    @username + 
    ' posted at ' + 
    @time_of_post.to_s + 
    ":</h3>" + @post_contents + 
    "</div>"
  end
end
#setup de db
DataMapper.finalize
DataMapper.auto_upgrade!

#nu de sinatra bits:
class Tinyboard < Sinatra::Base
  # De homepage
  get '/' do
    send_file 'homepage.html'
  end

  #maak een nieuwe post
  post '/newpost' do 
    #return early als de parameters niet goed zijn
    if params[:username].empty? || params[:message].empty?
      return [400, {}, ["Both your name and your post must be longer than zero characters."]]
    end
    # note to self : hash table met symbols als key ipv normale args
    Post.create(username: params[:username], time_of_post: Time.now, post_contents: params[:message])
    redirect to("/") #redirect naar homepage zodat de gebruiker direct zijn nieuwe post kan zien
  end

  #show a limited number of posts, in reverse chronological order
  get '/posts/:limit' do
    #return early als de parameter niet goed is
    number_of_posts = params[:limit].to_i
    if number_of_posts <= 0 
      # parse fail of negatief getal uit parse, beide is fout
      return [400, {}, ["The parameter must be an integer larger than zero."]] 
    end
    results = Post.all({:limit => number_of_posts, :order => [ :id.desc ]}).map(&:show) 
    results = ["No posts yet!"] if results.empty? #maak een default value
    [200, {}, results] # rs is een array en dus een enumerable en dus kan sinatra rs.each aanroepen  
  end

  #show all the posts
  get '/posts' do
    results = Post.all.map(&:show)
    results = ["No posts yet!"] if results.empty? #maak een default value
    [200, {}, results] # rs is een array en dus een enumerable en dus kan sinatra rs.each aanroepen  
  end

end