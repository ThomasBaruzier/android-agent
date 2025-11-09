# Android Agent

## Overview

This project uses a vision LLM API to try and simulate an automated phone assistant. It interacts with the device by issuing JSON commands that are then parsed, converted to root shell commands, and executed. The assistant can perform tasks such as clicking, double-clicking, long pressing, typing text, swiping, and simulating key presses like Home, Back, Volume Up, and more.

## Limitations

- The script is designed to work with Qwen 2.5 VL 72B. If you use a different model, it may or may not work. Qwen 2.5 VL 7B doesn't work well, for instance.
- It's slow, especially if ran locally and remotely on your computer. 2*RTX 3090s produces 1 action every ~15 seconds, due to context sliding on each query, all tokens must be ingested again. 
- The LLM will abandon the task if something goes wrong. It's not reliable. Simple tasks like playing songs or searching the internet will work, anything else that is harder probably won't.
- By using this script, you agree to do so at your own risk. I take no responsibility for any consequences resulting from the use of this agent.
- Will execute the `input` command as superuser. It won't brick your device, but if you are not comforable with this, now you know.

## Explanations

- The user provides a query that the assistant will try to fulfill. This could be anything from opening a specific app, to searching for information online, or interacting with UI elements.
- The assistant starts by going to the home screen. It then takes screenshots of the device’s screen to understand the context and generate responses based on that input.
- The script continues by processing screenshots and issuing commands in a loop. After each command, the assistant waits for the next screenshot, updates its context, and generates the next action.
- If a task is successfully completed, the assistant sends a "success" notification. If the task fails at any point, the assistant sends a "failure" notification.

## Requirements

- Rooted Android Device: The script uses root access to interact with the phone’s screen and simulate key presses, so a rooted Android device is required.
- Qwen 2.5 VL 72B API: This agent has been tested with Qwen 2.5 VL 72B, and compatibility with other models is not guaranteed. If you can't host it locally, you can try OpenRouter, as long as you trust how it handles your data.
- `curl`, `jq`, `termux-api`: Necessary for sending API requests, processing JSON data, and delivering notificatons.

## How to Use

- Environment:
   - Set `API_KEY` and `BASEURL`.
   - Ensure that you have root access on your Android device.
- Run the Script:
   - Using bash in Termux as a normal user. Superuser is not needed yet.

## Example

```bash
./agent.sh "Open Reddit and go to LocalLlama subreddit"
```
