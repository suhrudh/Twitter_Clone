let WaterCooler = {
  init(socket) {
    let channel = socket.channel('water_cooler:lobby', {})
    channel.join()
    this.listenForChats(channel)
  },

  listenForChats(channel) {
    document.getElementById("get_feed").onclick = function(e){
      e.preventDefault()
      channel.push('get_feed',{name:document.getElementById('loginUserName').value})
    }

    channel.on('get_feed',payload => {

        let chatBox = document.querySelector('#feed-box')
        let msgBlock = document.createElement('p')


        if(payload.status==1){
          payload["feed"].forEach(function(mention){
            msgBlock.insertAdjacentHTML('beforeend', mention)
            // msgBlock.insertAdjacentHTML('beforeend', `\n`)
            // msgBlock.appendChild("<br>")
            // document.write("<br>")
          })
          chatBox.appendChild(msgBlock)
    }
  })

    channel.on('notification',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')

      //msgBlock.insertAdjacentHTML('beforeend', `your feed :`)
      //if(payload.status==1){
      //  payload["notication"].forEach(function(tweet){
          msgBlock.insertAdjacentHTML('beforeend', payload["notify"]+"<br>")
      //  })
        // msgBlock.appendChild(button)
      //}
      chatBox.appendChild(msgBlock)
    })



    document.getElementById("my_mentions_channel").onclick = function(e){
      e.preventDefault()
      channel.push('get_my_mentions',{name:document.getElementById('loginUserName').value})
    }

    channel.on('get_my_mentions',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')


      if(payload.status==1){
        msgBlock.insertAdjacentHTML('beforeend', `below are tweets in which you are mentioned : `)
        payload["mentions"].forEach(function(mention){
          msgBlock.insertAdjacentHTML('beforeend', mention)
          // msgBlock.insertAdjacentHTML('beforeend', `\n`)
          // msgBlock.appendChild("<br>")
          // document.write("<br>")
        })
      }
      chatBox.appendChild(msgBlock)


    })

    document.getElementById("hashtag_tweets_channel").onclick = function(e){
      e.preventDefault()
      channel.push('get_tweets_by_hash_tag',{name:document.getElementById('loginUserName').value,hash_tag: document.getElementById('hashtag').value })
    }

    channel.on('get_tweets_by_hash_tag',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')

      if(payload.status==1){
        msgBlock.insertAdjacentHTML('beforeend', `below are the tweets by hash_tag : `+payload["hash_tag"])
        payload["hash_tag"].forEach(function(hash_tag){
          msgBlock.insertAdjacentHTML('beforeend', hash_tag)
        })
      }
      chatBox.appendChild(msgBlock)

    })



    document.getElementById("mentions_channel").onclick = function(e){
      e.preventDefault()
      channel.push('get_mentions_of',{name:document.getElementById('loginUserName').value,mentions_of: document.getElementById('mentions_of').value })
    }

    channel.on('mentions_channel',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')

      if(payload.status==1){
        msgBlock.insertAdjacentHTML('beforeend', `below are the mentions of the user : `+payload["mentions_of"])
        payload["mentions"].forEach(function(mention){
          msgBlock.insertAdjacentHTML('beforeend', mention)
        })
      }
      chatBox.appendChild(msgBlock)

    })


        document.getElementById("subscribe_to_channel").onclick = function(e){
          e.preventDefault()
          channel.push('subscribe_to_channel',{name:document.getElementById('loginUserName').value,subscriber_name: document.getElementById('subscribe_to').value })
        }


    channel.on('subscribe_to_channel',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')

      if(payload.status==1){
        msgBlock.insertAdjacentHTML('beforeend', `Subscribed to `+payload["subscribed_to"]+` sucessfully`)
      }
      chatBox.appendChild(msgBlock)

    })


    document.getElementById("user_register").onclick = function(e){
      e.preventDefault()
      channel.push('register_channel',{name: document.getElementById('loginUserName').value })
    }

    channel.on('register_channel',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')

      if(payload.status==1){
        msgBlock.insertAdjacentHTML('beforeend', `Registration Succesful`)
      }
      else{
        msgBlock.insertAdjacentHTML('beforeend', `Registrastion unsuccesful`)
        document.getElementById('loginUserName').value = ''
      }
      chatBox.appendChild(msgBlock)

    })




    document.getElementById("logInUser").onclick=function(e){
      e.preventDefault()
      channel.push('login_channel',{name:document.getElementById('loginUserName').value})
    }

    document.getElementById('user_register').addEventListener('submit', function(e){
      e.preventDefault()

      let userName = document.getElementById('user-name').value

      channel.push('shout', {name: userName})

      document.getElementById('user-name').value = ''
      document.getElementsById('user_register').style.visibility = "hidden"
    })

    // channel.on('shout', payload => {
    //   let chatBox = document.querySelector('#chat-box')
    //   let msgBlock = document.createElement('p')
    //
    //   msgBlock.insertAdjacentHTML('beforeend', `<b>${payload.name} is registered!!</b>`)
    //   chatBox.appendChild(msgBlock)
    // })

    channel.on('login_channel',payload => {
      let chatBox = document.querySelector('#chat-box')
      let msgBlock = document.createElement('p')

      if(payload.status==0){
        msgBlock.insertAdjacentHTML('beforeend', `The user is not found please enter the correct user name`)
        document.getElementById('loginUserName').value = ''
      }
      else{
        msgBlock.insertAdjacentHTML('beforeend', `Logged in sucessfully`)
        let name = document.querySelector('#name')
        let Block = document.createElement('h3')
        let nn = document.getElementById('loginUserName').value
        Block.insertAdjacentHTML('beforeend', `Hello `+nn+` Welcome back!!`)
        name.appendChild(Block)
      }
      chatBox.appendChild(msgBlock)
    })

    document.getElementById("tweet_channel").onclick = function(e){
      e.preventDefault()
      channel.push('tweet_channel',{name: document.getElementById('loginUserName').value,tweet:document.getElementById('user_tweet').value })
    }

document.getElementById("retweet_channel").onclick = function(e){
  e.preventDefault()
  channel.push('retweet',{name: document.getElementById('loginUserName').value,tweet:document.getElementById('user_tweet').value ,original_tweet_id:document.getElementById('original_tweet_id').value})
}

  }
}

export default WaterCooler
