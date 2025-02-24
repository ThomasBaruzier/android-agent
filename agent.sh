#!/bin/bash

maxhistory=8 # for 16k context max
apikey="$LOCAL_API_KEY"
baseurl="$BASEURL"
query='Open reddit as website, go to LocalLlama subreddit, sort by top posts'
[ -n "$1" ] && query="$*"

conversation_history=$(jq -n --rawfile sys system.txt '[
  {
    "role": "system",
    "content": [
      { "type": "text", "text": $sys }
    ]
  }
]')

perform_system_button() {
  local button="$1"
  case "$button" in
    "Home")
      su -c "input keyevent KEYCODE_HOME"; return;;
    "Back")
      su -c "input keyevent KEYCODE_BACK"; return;;
    "Recent_Apps")
      su -c "input keyevent KEYCODE_APP_SWITCH"; return;;
    "Enter")
      su -c "input keyevent KEYCODE_ENTER"; return;;
    "Volume_Up")
      su -c "input keyevent KEYCODE_VOLUME_UP"; return;;
    "Volume_Down")
      su -c "input keyevent KEYCODE_VOLUME_DOWN"; return;;
    "Notifications")
      su -c "cmd statusbar expand-notifications"; return;;
    "Quick_Settings")
      su -c "cmd statusbar expand-settings"; return;;
  esac
}

perform_click() {
  local x="$1" y="$2"
  echo "Clicking at x=$x, y=$y"
  su -c "input tap $x $y"
}

perform_long_press() {
  local x="$1" y="$2" duration="$3"
  echo "Long pressing at x=$x, y=$y for ${duration}ms"
  su -c "input swipe $x $y $x $y $duration"
}

perform_swipe() {
  local x1="$1" y1="$2" x2="$3" y2="$4"
  echo "Swiping from ($x1,$y1) to ($x2,$y2)"
  su -c "input swipe $x1 $y1 $x2 $y2 300"
}

transliterate_text() {
  local input="$1"
  [ -z "$input" ] && echo && return 1
  local output=$(
    printf "%s" "$input" | \
    sed -r '
      s/[èéêëÈÉÊË]/e/g;
      s/[àáâäãåÀÁÂÄÃÅ]/a/g;
      s/[ìíîïÌÍÎÏ]/i/g;
      s/[òóôõöøÒÓÔÕÖØ]/o/g;
      s/[ùúûüÙÚÛÜ]/u/g;
      s/[çÇ]/c/g;
      s/[^\x00-\x7F]//g
    '
  )
  echo "$output"
}

perform_text_input() {
  local text="$1"
  [ -z "$text" ] && echo 'No text provided for input' && return 1
  local ascii_text=$(transliterate_text "$text") || return 1
  local safe_text=$(printf %q "$ascii_text")
  echo "Writing: $safe_text"
  su -c "input text $safe_text"
}

parse_command() {
  local response
  response=$(jq -r '.choices[0].message.content' <<< "$1")
  [ "${response:0:3}" = '```' ] && response="${response:3}"
  [ "${response:0:4}" = 'json' ] && response="${response:4}"
  [ "${response: -3}" = '```' ] && response="${response: :-3}"
  echo "$response"
}

notify_and_exit() {
  local status="$1" message="$2"
  termux-notification --title "$message"
  echo "$message"
  exit "$status"
}

request() {
  echo "$conversation_history" | jq --arg apikey "$apikey" '{
    model: "Qwen2.5-VL-72B-Instruct-4.5bpw",
    messages: .,
    max_tokens: 512
  }' | curl -s "$baseurl/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $apikey" \
    -d @-
}

process_command() {
  local command="$1"
  local action=$(jq -r '.action' <<< "$command")

  case "$action" in
    "click")
      local coords=($(jq -r '.coordinate[]' <<< "$command"))
      perform_click "${coords[0]}" "${coords[1]}"
      ;;
    "long_press")
      local coords=($(jq -r '.coordinate[]' <<< "$command"))
      local duration
      duration=$(jq -r '.duration' <<< "$command")
      perform_long_press "${coords[0]}" "${coords[1]}" "$duration"
      ;;
    "swipe")
      local coords1=($(jq -r '.coordinate[]' <<< "$command"))
      local coords2=($(jq -r '.coordinate2[]' <<< "$command"))
      perform_swipe "${coords1[0]}" "${coords1[1]}" "${coords2[0]}" "${coords2[1]}"
      ;;
    "type")
      local text
      text=$(jq -r '.text' <<< "$command")
      perform_text_input "$text"
      ;;
    "system_button")
      local button
      button=$(jq -r '.button' <<< "$command")
      perform_system_button "$button"
      ;;
    "wait")
      local duration
      duration=$(jq -r '.duration' <<< "$command")
      echo "Waiting for ${duration}ms..."
      sleep $(bc <<< "scale=3; $duration/1000")
      ;;
    "terminate")
      local status
      status=$(jq -r '.status' <<< "$command")
      if [ "$status" = "success" ]; then
        notify_and_exit 0 "Task completed successfully"
      else
        notify_and_exit 1 "Task failed"
      fi
      ;;
    *)
      echo "Unknown command: $action"
      notify_and_exit 1 "Unknown command received"
      ;;
  esac
}

add_user_message() {
  conversation_history=$(
    echo "$conversation_history" | \
    jq --arg role "user" --arg text "$1" \
      --rawfile image "$2" --argjson max "$maxhistory" '
    . + [{
      "role": $role,
      "content": [
        { "type": "text", "text": $text },
        { "type": "image_url", "image_url": { "url": $image } }
      ]
    }]
    | if length > $max then ([.[0]] + .[2:]) else . end
  ')
}

add_assistant_message() {
  conversation_history=$(
    echo "$conversation_history" | \
    jq --arg role "assistant" --arg text "$1" \
      --argjson max "$maxhistory" '
    . + [{
      "role": $role,
      "content": [
        { "type": "text", "text": $text }
      ]
    }]
    | if length > $max then ([.[0]] + .[2:]) else . end
  ')
}

main() {
  echo "Started with query: $query"
  perform_system_button 'Home'

  while true; do
    sleep 1
    echo "Taking a screenshot..."
    tmpfile=$(mktemp)
    imagedata=$(su -c 'screencap -p 2>/dev/null' | base64 -w0)
    echo "data:image/png;base64,$imagedata" > "$tmpfile"

    add_user_message "$query" "$tmpfile"
    rm "$tmpfile"

    echo "Querying the API..."
    response=$(request)
    [ -z "$response" ] && notify_and_exit 1 "Failed to get API response"

    command=$(parse_command "$response")
    [ "$?" -ne 0 ] && notify_and_exit 1 "Failed to parse command"
    echo "Command: $command"

    add_assistant_message "$command"
    process_command "$command"
  done
}

main
