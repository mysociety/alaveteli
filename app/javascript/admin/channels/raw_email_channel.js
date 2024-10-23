import consumer from "../../channels/consumer"

export const createSubscription = ({ rawEmailID, cb }) => {
  const actions = {
    connected: function() {},
    disconnected: function() {},
    received: function(data) { cb(data) }
  }

  consumer.subscriptions.create(
    { channel: 'RawEmailChannel', id: rawEmailID }, actions
  )
}
