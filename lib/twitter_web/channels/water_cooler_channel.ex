defmodule TwitterWeb.WaterCoolerChannel do
  use TwitterWeb, :channel

  def join("water_cooler:lobby", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("register_channel",payload, socket) do
    result = :ets.match_object(:user_table, {payload["name"], :_})

    if length(result) == 0 do
      RequestHandler.register_user(payload["name"])
      payload = %{"status" => 1}
      push socket,"register_channel",payload
    else
      payload = %{"status" => 0}
      push socket,"register_channel",payload
    end
    result = :ets.match_object(:user_table, {:_, :_})
    IO.puts "before"
    IO.inspect(result)
    {:noreply,socket}
  end

  def handle_info({:notification, user, tweet, tweet_id}, socket) do
          notification = " notification: '#{user}', just tweeted :" <> tweet <> " ."
          push socket, "notification", %{"notify" => notification}
          {:noreply, socket}
  end
  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("login_channel",payload,socket) do
    result = :ets.match_object(:user_table, {payload["name"], :_})
    IO.puts("check")
    IO.inspect(result)
    if length(result)==0 do
      payload=%{"status"=>0}
      push socket,"login_channel",payload

    else
      IO.puts("insidefgrtg")

      RequestHandler.log_in_user(payload["name"])
      :ets.insert(:channel_id_table,{payload["name"],self()})
      payload = %{"status"=>1}
      IO.puts("channel_id $$$$$$$$$$$$")
      IO.inspect(self())
      IO.puts("channel_table $$$$$$$$$$$$")
      IO.inspect(:ets.match_object(:channel_id_table,{:"_",:"_"}))
      push socket,"login_channel",payload
    end
    result = :ets.match_object(:user_table, {:_, :_})
    IO.puts "logged"
    IO.inspect(result)
    {:noreply,socket}
  end


def handle_in("tweet_channel",payload,socket) do
  IO.puts("here----tweeys")
  value=:ets.lookup(:user_table, payload["name"])
  IO.inspect(value)
  ClientServer.send_tweet(elem(Enum.at(value,0),1),payload["tweet"],nil)
  tweets =  :ets.match_object(:tweets,{:_,:_,:_,:_})
  IO.puts("tweets")
  IO.inspect(tweets)
  {:noreply,socket}
end

def handle_in("subscribe_to_channel",payload,socket) do
  value=:ets.lookup(:user_table, payload["name"])
  IO.inspect(value)
  ClientServer.subscribe_to(elem(Enum.at(value,0),1),payload["subscriber_name"])
  subs =  :ets.match_object(:subscribers,{:_,:_})
  IO.puts("subscribers")
  IO.inspect(subs)
  push socket,"subscribe_to_channel",%{"status"=>1,"subscribed_to"=>payload["subscriber_name"]}
  {:noreply,socket}
end

def handle_in("get_mentions_of",payload,socket) do

  mentions = RequestHandler.get_mention_tweets(payload["mentions_of"])
  tweets = Enum.map(mentions,fn x -> elem(x,2) end)
  IO.puts("mentions--------")
  IO.inspect(tweets)
  push socket,"get_mentions_of",%{"status"=>1,"mentions"=>tweets,"mentions_of"=>payload["mentions_of"]}
  {:noreply,socket}
end

def handle_in("get_tweets_by_hash_tag",payload,socket) do

  mentions = RequestHandler.get_hashtag_tweets(payload["hash_tag"])
  tweets = Enum.map(mentions,fn x -> elem(x,2) end)
  IO.puts("hash_tags--------")
  IO.inspect(tweets)
  push socket,"get_tweets_by_hash_tag",%{"status"=>1,"tweets"=>tweets,"hash_tag"=>payload["hash_tag"]}
  {:noreply,socket}
end

def handle_in("get_my_mentions",payload,socket) do

  value=:ets.lookup(:user_table, payload["name"])
  IO.inspect(value)
  mentions = ClientServer.get_tweets_by_mentions(elem(Enum.at(value,0),1))
  tweets = Enum.map(mentions,fn x -> elem(x,2) end)
  IO.puts("my mentions ----- ")
  IO.inspect(tweets)
  push socket,"get_my_mentions",%{"status"=>1,"mentions"=>tweets}
  {:noreply,socket}
end

def handle_in("get_feed",payload,socket) do

  value=:ets.lookup(:user_table, payload["name"])
  IO.inspect(value)
  feed = ClientServer.get_feed(elem(Enum.at(value,0),1))
  IO.puts("feeeeeeed")
  IO.inspect(feed)
  tweets = Enum.map(feed,fn x -> tweetProcessing(Enum.at(x,0)) end)
  IO.puts("my feed ----- ")
  IO.inspect(tweets)
  push socket,"get_feed",%{"status"=>1,"feed"=>tweets}
  {:noreply,socket}
end

def tweetProcessing(x) do
    if elem(x,3) == nil do
      elem(x,0)<>" : "<>elem(x,2)<> " " <> "Tweet id: "<>elem(x,1)
    else
      IO.inspect(:ets.match_object(:tweets,{:"_",elem(x,3),:"_",:_}))
      [original_tweet] = :ets.match_object(:tweets,{:"_",elem(x,3),:"_",:_})

      elem(x,0)<>" : "<>elem(x,2)<> " , it's a retweet of "<> elem(original_tweet,0)<>" : "<> elem(original_tweet,2)<>" ."
    end
end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (water_cooler:lobby).


  def handle_in("shout", payload, socket) do
    RequestHandler.register_user(payload["name"])
    pid=RequestHandler.log_in_user(payload["name"])
    # :timer.sleep(1000)
    result = :ets.match_object(:user_table, {:_, :_})
    IO.puts "before"
    IO.inspect(result)
    IO.puts("pid----")
    IO.inspect(pid)
    IO.puts("here-----")
    (ClientServer.send_tweet(pid,"hello #twitter ",nil))
    tweets =  :ets.match_object(:tweets,{:_,:_,:_,:_})
    IO.puts("tweets")
    IO.inspect(tweets)
    IO.puts("hashhh")
    IO.inspect(:ets.match_object(:hashtags, {:_,:_}))
    # result = :ets.match_object(:user_table, {:_, :_})
    # IO.puts "after"
    # IO.inspect(result)
    # IO.puts("here-----")
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("retweet",payload,socket) do
    value=:ets.lookup(:user_table, payload["name"])
    IO.inspect(value)
    IO.inspect(payload["original_tweet_id"])
    IO.puts "original_tweet_id-----------"
    ClientServer.send_tweet(elem(Enum.at(value,0),1),payload["tweet"],payload["original_tweet_id"])
    tweets =  :ets.match_object(:tweets,{:_,:_,:_,:_})
    IO.puts("retweets---------")
    IO.inspect(tweets)
    {:noreply,socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
