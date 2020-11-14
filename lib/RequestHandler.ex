defmodule RequestHandler do
  use GenServer

  def init(_default) do
    :ets.new(:user_table, [:set, :public, :named_table])
    :ets.new(:tweets, [:set, :public, :named_table])
    :ets.new(:subscribers, [:bag, :public, :named_table])
    :ets.new(:hashtags, [:bag, :public, :named_table])
    :ets.new(:mentions, [:bag, :public, :named_table])
    # IO.inspect(:ets.whereis(:user_table))
    {:ok,[]}
  end

  def start_engine() do
    GenServer.start_link(__MODULE__,[],name: :engine)
  end

  #registering user
  def register_user(user_id) do
    GenServer.call(:engine,{:register_user,user_id})
  end

  def handle_call(:dummy,_from,state) do
    :timer.sleep(10)
    {:reply,state,state}
  end

  def setSubscribers(subscriber_id,subscribe_to_id) do
    GenServer.call(:engine,{:subscribe,subscriber_id,subscribe_to_id})
  end


  def store_tweets(msg,user_id,original_tweet_id) do
    tweet_id = UUID.uuid4(:hex)
    GenServer.call(:engine,:dummy)
    GenServer.call(:engine,{:storeTweet,tweet_id,msg,user_id,original_tweet_id})
  end

  def handle_call({:storeTweet,tweet_id,msg,user_id,original_tweet_id},_from,state) do
    :ets.insert(:tweets, {user_id,tweet_id,msg,original_tweet_id})
    GenServer.cast(:engine,{:hashtags_mentions,tweet_id,msg,user_id})

    #GenServer.call(:engine,{:multicast_tweet_to_users,user_id,tweet_id})
    multicast_tweet_to_users(user_id,tweet_id)
    {:reply,tweet_id,state}
  end

  def handle_cast({:hashtags_mentions,tweet_id,msg,user_id},state) do

    hashAndMentions=msg |> String.replace("@"," @") |> String.replace("#"," #") |>
                    String.split() |> Enum.filter(fn x-> String.at(x,0)=="#" || String.at(x,0)=="@" end) |>
                    Enum.filter(fn x-> String.length(x)>1 end)

    mentions =    ((hashAndMentions |> Enum.filter (fn x->String.at(x,0)=="@" end)) |>
                    Enum.map(fn x-> String.replace(x,"@","") end) |> Enum.uniq())
                    |> Enum.filter(fn x-> :ets.lookup(:user_table,x)!=[] end)

   Enum.each(mentions,fn mention-> :ets.insert(:mentions, {mention,tweet_id}) end)

   hashTags = (hashAndMentions |> Enum.filter (fn x->String.at(x,0)=="#" end) )|>
              Enum.map(fn x -> String.replace(x,"#","") end)|> Enum.uniq()

  IO.inspect(hashTags)
  Enum.each(hashTags,fn htags-> :ets.insert(:hashtags, {htags,tweet_id}) end)
  {:noreply,state}
  end

  def handle_call({:register_user,user_id},_from,state) do
    success = case :ets.lookup(:user_table,user_id) do
      []-> :ets.insert(:user_table, {user_id,nil}) #null as assumed that the user is not logged in
      _ -> false
    end

    {:reply,success, state}
  end

  def multicast_tweet_to_users(user_id,tweet_id) do
    followers  = :ets.match(:subscribers,{:"$1",user_id})
    Enum.each(followers,fn x-> send_notification(x,tweet_id)end)
  end

  def send_notification([user_id],tweet_id) do
     case :ets.lookup(:user_table,user_id) do
       [{user_id,nil}] -> "offline #{user_id}"
       [{^user_id,pid}] -> GenServer.cast(pid,{:store_notifications,tweet_id})
        _ -> IO.puts "not possible"
     end
  end

  def handle_call({:subscribe,subscriber_id,subscribe_to_id},_from,state) do
    :ets.insert(:subscribers, {subscriber_id,subscribe_to_id})
    {:reply,state,state}
  end

  def getTweets(subscribed_to) do
    listOfTweets = Enum.map(subscribed_to,fn [x]-> fetch_tweets_by_id(x) end)
  end

  def fetch_tweets_by_id(user_id) do
    tweets =  :ets.match_object(:tweets,{user_id,:"$1",:_,:_})
  end

  def handle_call({:get_subscribed_tweets,user_id},_from,state) do
    subscribed_to = :ets.match(:subscribers,{user_id,:"$1"})
    tweetList=getTweets(subscribed_to)
    {:reply,tweetList,state}
  end

  def get_feed_by_user_id(user_id) do
    GenServer.call(:engine,{:get_subscribed_tweets,user_id})
  end

  def get_hashtag_tweets(hash_tag) do
    GenServer.call(:engine,{:get_tweets_with_hash_tag,hash_tag})
  end

  def get_mention_tweets(user_id) do
    GenServer.call(:engine,{:get_tweets_by_mentions,user_id})
  end

  def handle_call({:get_tweets_with_hash_tag,hash_tag},_from,state) do
    tweetIds = :ets.match(:hashtags,{hash_tag,:"$1"})
    listOfTweets = Enum.map(tweetIds,fn [x] -> get_tweet_content_from_id(x)end)
    {:reply,listOfTweets,state}
  end

  def handle_call({:get_tweets_by_mentions,user_id},_from,state) do
    tweetIds = :ets.match(:mentions,{user_id,:"$1"})
    listOfTweets = Enum.map(tweetIds,fn [x] -> get_tweet_content_from_id(x)end)
    {:reply,listOfTweets,state}
  end

  def get_tweet_content_from_id(tweet_id) do
    [tweet] = :ets.match_object(:tweets,{:_,tweet_id,:_,:_})
    tweet
  end

  #logging in user
  def log_in_user(user_id) do
    GenServer.call(:engine,{:login_user,user_id})
  end

  def handle_call({:login_user,user_id},_from,state) do

    IO.inspect(:ets.match_object(:user_table, {:_, :_}))
    IO.puts("user_id: #{user_id}")
    pid = case :ets.lookup(:user_table,user_id) do
      [] -> nil
      _ -> login_client(user_id)
    end
    {:reply, pid, state}
  end

  def login_client(user_id) do
    {:ok , pid} = ClientServer.start_client([id: user_id, notify: []])
    :ets.insert(:user_table, {user_id,pid})
    # IO.puts("pid-----")
    # IO.inspect(pid)
    result = :ets.match_object(:user_table, {:_, :_})
    IO.puts "in login"
    IO.inspect(result)
    pid
  end



end
