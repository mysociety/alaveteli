import consumer from "./consumer"

consumer.subscriptions.create("JobStatusChannel", {
  received(data) {
    const statusElement = document.getElementById("job-status")
    const progressElement = document.getElementById("job-progress")
    const resultElement = document.getElementById("job-result")

    if (statusElement) statusElement.textContent = data.status
    if (progressElement) progressElement.value = data.progress
    if (data.result && resultElement) resultElement.textContent = data.result
  }
})
