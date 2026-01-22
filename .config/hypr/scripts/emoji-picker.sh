#!/bin/bash

# Emoji picker for Wayland
# Uses wofi with emoji data

EMOJI_FILE="$HOME/.config/hypr/scripts/emojis.txt"

# Create emoji file if it doesn't exist
if [ ! -f "$EMOJI_FILE" ]; then
    cat > "$EMOJI_FILE" << 'EOF'
😀 grinning face
😁 beaming face
😂 face with tears of joy
🤣 rolling on the floor laughing
😃 grinning face with big eyes
😄 grinning face with smiling eyes
😅 grinning face with sweat
😆 grinning squinting face
😉 winking face
😊 smiling face with smiling eyes
😋 face savoring food
😎 smiling face with sunglasses
😍 smiling face with heart-eyes
😘 face blowing a kiss
🥰 smiling face with hearts
😗 kissing face
😙 kissing face with smiling eyes
🥲 smiling face with tear
😚 kissing face with closed eyes
🙂 slightly smiling face
🤗 hugging face
🤔 thinking face
🤭 face with hand over mouth
🤫 shushing face
🤥 lying face
😶 face without mouth
😏 smirking face
😒 unamused face
🙄 face with rolling eyes
😬 grimacing face
😮‍💨 face exhaling
🤐 zipper-mouth face
😌 relieved face
😔 pensive face
😪 sleepy face
🤤 drooling face
😴 sleeping face
👍 thumbs up
👎 thumbs down
👋 waving hand
🙏 folded hands
💪 flexed biceps
🔥 fire
❤️ red heart
💯 hundred points
✅ check mark
❌ cross mark
⭐ star
🎉 party popper
🚀 rocket
💻 laptop
📱 phone
📧 email
📝 memo
🔗 link
EOF
fi

# Select emoji
SELECTED=$(cat "$EMOJI_FILE" | wofi --dmenu -p "Emoji" | awk '{print $1}')

if [ -n "$SELECTED" ]; then
    # Copy to clipboard
    echo -n "$SELECTED" | wl-copy
    
    # Type it using wtype (install wtype package)
    if command -v wtype &> /dev/null; then
        wtype "$SELECTED"
    fi
fi
