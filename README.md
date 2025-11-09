# Android agent

## Overview

This project uses a vision LLM API to simulate an automated phone assistant. It interacts with the device by issuing JSON commands that are then parsed, converted to root shell commands, and executed. The assistant can perform tasks such as clicking, double-clicking, long pressing, typing text, swiping, and simulating key presses like home, back, and volume up.

## Limitations

* The script is designed to work with Qwen 2.5 VL 72B. If you use a different model, it may or may not work. For instance, Qwen 2.5 VL 7B does not work well.
* It is slow, especially if run locally and remotely on your computer. Two RTX 3090s produce one action every 15 seconds, due to context sliding on each query, all tokens must be ingested again.
* The LLM will abandon the task if something goes wrong. It is not reliable. Simple tasks like playing songs or searching the internet will work, anything else that is harder probably will not.
* By using this script, you agree to do so at your own risk. I take no responsibility for any consequences resulting from the use of this agent.
* It will execute the `input` command as superuser. It will not brick your device, but if you are not comfortable with this, now you know.

## Explanations

* The user provides a query that the assistant will try to fulfill. This could be anything from opening a specific app, to searching for information online, or interacting with UI elements.
* The assistant starts by going to the home screen. It then takes screenshots of the device’s screen to understand the context and generate responses based on that input.
* The script continues by processing screenshots and issuing commands in a loop. After each command, the assistant waits for the next screenshot, updates its context, and generates the next action.
* If a task is successfully completed, the assistant sends a "success" notification. If the task fails at any point, the assistant sends a "failure" notification.

## Requirements

* Rooted android device: The script uses root access to interact with the phone’s screen and simulate key presses, so a rooted android device is required.
* Qwen 2.5 VL 72B API: This agent has been tested with Qwen 2.5 VL 72B, and compatibility with other models is not guaranteed. If you cannot host it locally, you can try OpenRouter, as long as you trust how it handles your data.
* `curl`, `jq`, `termux-api`: Necessary for sending API requests, processing JSON data, and delivering notifications.

## How to use in Termux

1. Set the required environment variables.
   ```bash
   export API_KEY="your_api_key_here"
   export BASEURL="your_api_base_url_here"
   ```
2. Ensure the script is executable:
   ```bash
   chmod +x agent.sh
   ```
3. Run the script providing your task as a string argument. The script does not need to be run as a superuser, as it will call `su` for commands that require it.
   ```bash
   ./agent.sh "your task description here"
   ```
