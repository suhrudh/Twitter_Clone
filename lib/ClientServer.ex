defmodule ClientServer do
  use GenServer
  def init(state) do
    {:ok,state}
  end

  def start_client(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def send_tweet(pid,message,original_tweet_id) do
    GenServer.call(pid,{:send_tweet,message,original_tweet_id})
  end

  def handle_call({:send_tweet,message,original_tweet_id},_from,state) do
    tweet_id = RequestHandler.store_tweets(message,state[:id],original_tweet_id)
    {:reply,tweet_id,state}
  end

  def subscribe_to(pid,subscribe_to_id) do
    GenServer.call(pid,{:subscribe_to,subscribe_to_id})
  end

  def handle_call({:subscribe_to,subscribe_to_id},_from,state) do
    RequestHandler.setSubscribers(state[:id],subscribe_to_id)
    {:reply,state,state}
  end



  def get_feed(pid) do
    GenServer.call(pid,:get_feed)
  end

  def handle_call(:get_feed,_from,state) do
    tweets = RequestHandler.get_feed_by_user_id(state[:id])
    IO.puts("feed-----------")
    IO.inspect(tweets)
    {:reply,tweets,state}
  end

  def retweets(user1,user2) do
     user2Tweet=Enum.random(:ets.lookup(:tweets, user2))
     pid=elem(Enum.at(:ets.lookup(:user_table, user1),0),1)
     ClientServer.send_tweet(pid,elem(user2Tweet,2),elem(user2Tweet,1))
  end

  def handle_cast({:store_notifications,tweet_id},state)do
    [tweet] = :ets.match_object(:tweets,{:"_",tweet_id,:"_",:"_"})
    IO.puts("abc-----------")
    IO.inspect(:ets.match_object(:channel_id_table,{:"_",:"_"}))
    [cid] = :ets.lookup(:channel_id_table,state[:id])
    send(elem(cid,1), {:notification, elem(tweet,0), elem(tweet,2), elem(tweet,1)})
    l=state[:notify]++[tweet_id]
    {:noreply,[id: state[:id], notify: l]}
  end

  def handle_call(:get_notifications,_from,state) do
    :timer.sleep(1000)
    {:reply,state[:notify],state}
  end

  def get_tweets_by_hash_tag(pid,hash_tag) do
    GenServer.call(pid,{:get_tweets_with_hash_tag,hash_tag})
  end

  def handle_call({:get_tweets_with_hash_tag,hash_tag},_from,state) do
    tweets = GenServer.call(:engine,{:get_tweets_with_hash_tag,hash_tag})
    {:reply,tweets,state}
  end

  def get_tweets_by_mentions(pid) do
    GenServer.call(pid,:get_tweets_by_mentions)
  end

  def handle_call(:get_tweets_by_mentions,_from,state) do
    tweets = GenServer.call(:engine,{:get_tweets_by_mentions,state[:id]})
    {:reply,tweets,state}
  end

  def logout(pid) do
    GenServer.call(pid,:logout)
  end

  def handle_call(:logout,_from,state) do
      :ets.insert(:user_table, {state[:id],nil})
      {:reply,state,state}
  end

end
