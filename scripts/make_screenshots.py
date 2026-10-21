#!/usr/bin/env python3
import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WIDTH, HEIGHT = 768, 1376

def get_font(size, bold=False):
    font_paths = [
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for p in font_paths:
        if os.path.exists(p):
            try:
                # index 1 or 0 for TTC
                index = 1 if (bold and p.endswith(".ttc")) else 0
                return ImageFont.truetype(p, size, index=index)
            except Exception:
                try:
                    return ImageFont.truetype(p, size)
                except Exception:
                    pass
    return ImageFont.load_default()

def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)

def create_base_canvas(title_pill, subtitle):
    # Studio light gradient background
    im = Image.new("RGBA", (WIDTH, HEIGHT), (245, 247, 250, 255))
    draw = ImageDraw.Draw(im)
    
    # Subtle radial or vertical glow
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        r = int(244 - ratio * 12)
        g = int(248 - ratio * 10)
        b = int(252 - ratio * 8)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b, 255))
        
    # Title Pill Header
    f_pill = get_font(34, bold=True)
    f_sub = get_font(18, bold=False)
    
    # Measure text
    pill_bbox = draw.textbbox((0, 0), title_pill, font=f_pill)
    pill_w = pill_bbox[2] - pill_bbox[0]
    pill_h = pill_bbox[3] - pill_bbox[1]
    
    pill_pad_x = 36
    pill_pad_y = 14
    box_w = pill_w + pill_pad_x * 2
    box_h = pill_h + pill_pad_y * 2
    box_x = (WIDTH - box_w) // 2
    box_y = 60
    
    # Pill background with soft cyan/indigo gradient effect
    draw.rounded_rectangle(
        [box_x, box_y, box_x + box_w, box_y + box_h],
        radius=26,
        fill=(228, 246, 254, 255),
        outline=(180, 225, 250, 255),
        width=1
    )
    
    # Text inside pill
    text_x = box_x + (box_w - pill_w) // 2
    text_y = box_y + (box_h - pill_h) // 2 - 3
    draw.text((text_x, text_y), title_pill, fill=(15, 23, 42, 255), font=f_pill)
    
    # Subtitle
    sub_bbox = draw.textbbox((0, 0), subtitle, font=f_sub)
    sub_w = sub_bbox[2] - sub_bbox[0]
    draw.text(((WIDTH - sub_w) // 2, box_y + box_h + 16), subtitle, fill=(100, 116, 139, 255), font=f_sub)
    
    return im

def draw_phone_frame(base_img):
    # Phone dimensions
    pw, ph = 460, 940
    px = (WIDTH - pw) // 2
    py = 210
    radius = 52
    
    # Shadow layer
    shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([px - 4, py + 12, px + pw + 4, py + ph + 24], radius=radius + 4, fill=(30, 41, 59, 45))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    base_img.alpha_composite(shadow)
    
    draw = ImageDraw.Draw(base_img)
    # Phone outer frame (sleek aluminum / titanium silver)
    draw.rounded_rectangle([px, py, px + pw, py + ph], radius=radius, fill=(218, 224, 233, 255), outline=(180, 190, 205, 255), width=2)
    # Inner border
    draw.rounded_rectangle([px + 4, py + 4, px + pw - 4, py + ph - 4], radius=radius - 2, fill=(240, 244, 248, 255), outline=(200, 208, 218, 255), width=1)
    
    # Screen bezel
    screen_pad = 12
    sx1 = px + screen_pad
    sy1 = py + screen_pad
    sx2 = px + pw - screen_pad
    sy2 = py + ph - screen_pad
    s_radius = radius - 10
    
    # Screen background (Pure clean light theme)
    draw.rounded_rectangle([sx1, sy1, sx2, sy2], radius=s_radius, fill=(255, 255, 255, 255))
    
    # Punch hole camera
    cam_x = px + pw // 2
    cam_y = sy1 + 18
    draw.ellipse([cam_x - 7, cam_y - 7, cam_x + 7, cam_y + 7], fill=(20, 24, 30, 255))
    draw.ellipse([cam_x - 3, cam_y - 3, cam_x + 3, cam_y + 3], fill=(10, 14, 20, 255))
    
    # Status bar
    f_stat = get_font(13, bold=True)
    draw.text((sx1 + 24, sy1 + 12), "9:41", fill=(30, 41, 59, 255), font=f_stat)
    # battery / wifi icons text representation
    draw.text((sx2 - 64, sy1 + 12), "5G  85%", fill=(71, 85, 105, 255), font=get_font(12, bold=True))
    
    # Home bar at bottom
    bar_w = 120
    bar_x = px + (pw - bar_w) // 2
    bar_y = sy2 - 14
    draw.rounded_rectangle([bar_x, bar_y, bar_x + bar_w, bar_y + 4], radius=2, fill=(148, 163, 184, 255))
    
    return sx1, sy1 + 42, sx2, sy2 - 28

def generate_ss5_browser_drop():
    im = create_base_canvas("Browser Drop PC Sync", "Zero Install • Transfer to Any PC, Mac or iOS via Browser")
    sx1, sy1, sx2, sy2 = draw_phone_frame(im)
    draw = ImageDraw.Draw(im)
    
    sw = sx2 - sx1
    # App Header inside screen
    f_h = get_font(18, bold=True)
    f_p = get_font(13, bold=False)
    f_p_bold = get_font(13, bold=True)
    
    # Top bar
    draw.text((sx1 + 20, sy1 + 10), "Browser Drop", fill=(15, 23, 42, 255), font=f_h)
    # Green status dot + "Server Running"
    draw.ellipse([sx2 - 130, sy1 + 16, sx2 - 122, sy1 + 24], fill=(16, 185, 129, 255))
    draw.text((sx2 - 116, sy1 + 13), "Active Server", fill=(16, 185, 129, 255), font=get_font(12, bold=True))
    
    # Card 1: Server URL Card
    c1_y = sy1 + 48
    c1_h = 100
    draw.rounded_rectangle([sx1 + 16, c1_y, sx2 - 16, c1_y + c1_h], radius=16, fill=(245, 249, 255, 255), outline=(210, 230, 255, 255), width=1)
    
    draw.text((sx1 + 30, c1_y + 14), "LOCAL NETWORK ADDRESS", fill=(100, 116, 139, 255), font=get_font(10, bold=True))
    draw.text((sx1 + 30, c1_y + 34), "http://192.168.1.15:8080", fill=(14, 116, 144, 255), font=get_font(17, bold=True))
    draw.text((sx1 + 30, c1_y + 64), "Open this URL on any PC or phone browser", fill=(100, 116, 139, 255), font=get_font(11, bold=False))
    
    # Copy badge
    draw.rounded_rectangle([sx2 - 86, c1_y + 32, sx2 - 28, c1_y + 60], radius=8, fill=(14, 165, 233, 255))
    draw.text((sx2 - 76, c1_y + 38), "Copy", fill=(255, 255, 255, 255), font=get_font(12, bold=True))
    
    # Card 2: QR Code Card
    c2_y = c1_y + c1_h + 16
    c2_h = 290
    draw.rounded_rectangle([sx1 + 16, c2_y, sx2 - 16, c2_y + c2_h], radius=20, fill=(250, 252, 255, 255), outline=(226, 232, 240, 255), width=1)
    
    # QR Code placeholder box
    qr_size = 170
    qr_x = sx1 + (sw - qr_size) // 2
    qr_y = c2_y + 24
    draw.rounded_rectangle([qr_x, qr_y, qr_x + qr_size, qr_y + qr_size], radius=12, fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=1)
    
    # Draw a stylized QR code pattern
    import random
    random.seed(42)
    step = 10
    # Corner squares
    for cx, cy in [(qr_x + 14, qr_y + 14), (qr_x + qr_size - 44, qr_y + 14), (qr_x + 14, qr_y + qr_size - 44)]:
        draw.rectangle([cx, cy, cx + 30, cy + 30], fill=(15, 23, 42, 255))
        draw.rectangle([cx + 6, cy + 6, cx + 24, cy + 24], fill=(255, 255, 255, 255))
        draw.rectangle([cx + 10, cy + 10, cx + 20, cy + 20], fill=(15, 23, 42, 255))
    # random data grid
    for gx in range(qr_x + 12, qr_x + qr_size - 12, step):
        for gy in range(qr_y + 12, qr_y + qr_size - 12, step):
            if ((gx < qr_x + 50 and gy < qr_y + 50) or
                (gx > qr_x + qr_size - 54 and gy < qr_y + 50) or
                (gx < qr_x + 50 and gy > qr_y + qr_size - 54)):
                continue
            if random.random() > 0.45:
                draw.rectangle([gx, gy, gx + step - 2, gy + step - 2], fill=(15, 23, 42, 255))
                
    draw.text((sx1 + (sw - 230) // 2, qr_y + qr_size + 20), "Scan with Camera to Connect", fill=(30, 41, 59, 255), font=get_font(14, bold=True))
    draw.text((sx1 + (sw - 250) // 2, qr_y + qr_size + 44), "No app required on receiver device", fill=(100, 116, 139, 255), font=get_font(12, bold=False))
    
    # Card 3: Files Shared Queue
    c3_y = c2_y + c2_h + 16
    c3_h = 240
    draw.rounded_rectangle([sx1 + 16, c3_y, sx2 - 16, c3_y + c3_h], radius=16, fill=(248, 250, 252, 255), outline=(226, 232, 240, 255), width=1)
    
    draw.text((sx1 + 30, c3_y + 16), "SHARED FILES IN BROWSER", fill=(100, 116, 139, 255), font=get_font(11, bold=True))
    
    # File Item 1
    f1_y = c3_y + 44
    draw.rounded_rectangle([sx1 + 26, f1_y, sx1 + 64, f1_y + 38], radius=8, fill=(224, 242, 254, 255))
    draw.text((sx1 + 33, f1_y + 11), "MP4", fill=(2, 132, 199, 255), font=get_font(11, bold=True))
    draw.text((sx1 + 76, f1_y + 3), "4K_Drone_Cinematic.mp4", fill=(15, 23, 42, 255), font=f_p_bold)
    draw.text((sx1 + 76, f1_y + 22), "1.82 GB  •  Downloaded by MacBook Pro", fill=(100, 116, 139, 255), font=get_font(11, bold=False))
    
    # File Item 2
    f2_y = f1_y + 54
    draw.rounded_rectangle([sx1 + 26, f2_y, sx1 + 64, f2_y + 38], radius=8, fill=(254, 243, 199, 255))
    draw.text((sx1 + 33, f2_y + 11), "ZIP", fill=(217, 119, 6, 255), font=get_font(11, bold=True))
    draw.text((sx1 + 76, f2_y + 3), "Source_Code_Archive.zip", fill=(15, 23, 42, 255), font=f_p_bold)
    draw.text((sx1 + 76, f2_y + 22), "420 MB  •  Ready for download", fill=(100, 116, 139, 255), font=get_font(11, bold=False))
    
    # Add files button
    btn_y = f2_y + 60
    draw.rounded_rectangle([sx1 + 30, btn_y, sx2 - 30, btn_y + 44], radius=12, fill=(14, 165, 233, 255))
    draw.text((sx1 + (sw - 120) // 2, btn_y + 12), "+ Add More Files", fill=(255, 255, 255, 255), font=get_font(14, bold=True))
    
    return im.convert("RGB")

def generate_ss6_walkie_talkie():
    im = create_base_canvas("Mesh Walkie-Talkie Chat", "Offline Direct Voice & Encrypted Text • 0ms Lag")
    sx1, sy1, sx2, sy2 = draw_phone_frame(im)
    draw = ImageDraw.Draw(im)
    
    sw = sx2 - sx1
    f_h = get_font(17, bold=True)
    f_p = get_font(13, bold=False)
    f_p_bold = get_font(13, bold=True)
    
    # Header area with peer info and avatar
    avatar_path = "/Users/piyush/Documents/p2p-chatting/assets/avatars/avatar_3.png"
    if os.path.exists(avatar_path):
        av = Image.open(avatar_path).convert("RGBA").resize((42, 42), Image.Resampling.LANCZOS)
        # Circular mask
        mask = Image.new("L", (42, 42), 0)
        m_draw = ImageDraw.Draw(mask)
        m_draw.ellipse([0, 0, 42, 42], fill=255)
        im.paste(av, (sx1 + 20, sy1 + 6), mask)
    else:
        draw.ellipse([sx1 + 20, sy1 + 6, sx1 + 62, sy1 + 48], fill=(14, 165, 233, 255))
        
    draw.text((sx1 + 72, sy1 + 8), "Quantum Bot (Alex)", fill=(15, 23, 42, 255), font=f_h)
    draw.ellipse([sx1 + 72, sy1 + 32, sx1 + 80, sy1 + 40], fill=(16, 185, 129, 255))
    draw.text((sx1 + 86, sy1 + 29), "Direct Socket • 0.3ms Ping", fill=(16, 185, 129, 255), font=get_font(11, bold=True))
    
    # Encryption badge
    draw.rounded_rectangle([sx2 - 95, sy1 + 14, sx2 - 16, sy1 + 38], radius=8, fill=(241, 245, 249, 255), outline=(203, 213, 225, 255), width=1)
    draw.text((sx2 - 88, sy1 + 19), "🔒 E2E Mesh", fill=(71, 85, 105, 255), font=get_font(10, bold=True))
    
    # Divider line
    draw.line([(sx1 + 16, sy1 + 56), (sx2 - 16, sy1 + 56)], fill=(241, 245, 249, 255), width=1)
    
    # Chat bubbles
    # Bubble 1: Incoming from Alex
    b1_y = sy1 + 76
    b1_w = 280
    b1_h = 72
    draw.rounded_rectangle([sx1 + 20, b1_y, sx1 + 20 + b1_w, b1_y + b1_h], radius=16, fill=(241, 245, 249, 255))
    draw.text((sx1 + 34, b1_y + 12), "Bro, the 3GB file reached in 35s!", fill=(15, 23, 42, 255), font=f_p_bold)
    draw.text((sx1 + 34, b1_y + 32), "No internet needed at all 🔥", fill=(30, 41, 59, 255), font=f_p)
    draw.text((sx1 + b1_w - 38, b1_y + 50), "9:40", fill=(148, 163, 184, 255), font=get_font(10, bold=False))
    
    # Bubble 2: Outgoing from User
    b2_y = b1_y + b1_h + 18
    b2_w = 290
    b2_h = 76
    b2_x = sx2 - 20 - b2_w
    draw.rounded_rectangle([b2_x, b2_y, b2_x + b2_w, b2_y + b2_h], radius=16, fill=(14, 165, 233, 255))
    draw.text((b2_x + 16, b2_y + 12), "Told you! ZeroPing uses raw TCP", fill=(255, 255, 255, 255), font=f_p_bold)
    draw.text((b2_x + 16, b2_y + 32), "sockets over local subnet Wi-Fi.", fill=(240, 249, 255, 255), font=f_p)
    draw.text((b2_x + b2_w - 50, b2_y + 54), "9:41 ✓✓", fill=(224, 242, 254, 255), font=get_font(10, bold=True))
    
    # Bubble 3: Audio Walkie-Talkie Note (Incoming)
    b3_y = b2_y + b2_h + 20
    b3_w = 260
    b3_h = 78
    draw.rounded_rectangle([sx1 + 20, b3_y, sx1 + 20 + b3_w, b3_y + b3_h], radius=18, fill=(241, 245, 249, 255), outline=(226, 232, 240, 255), width=1)
    # Play circle
    draw.ellipse([sx1 + 32, b3_y + 18, sx1 + 74, b3_y + 60], fill=(14, 165, 233, 255))
    # Play triangle
    draw.polygon([(sx1 + 49, b3_y + 31), (sx1 + 49, b3_y + 47), (sx1 + 63, b3_y + 39)], fill=(255, 255, 255, 255))
    # Soundwave bars
    wave_x = sx1 + 86
    heights = [8, 14, 22, 12, 18, 26, 16, 28, 20, 14, 24, 12, 8]
    for i, h in enumerate(heights):
        wx = wave_x + i * 11
        wy = b3_y + 39 - h // 2
        draw.rounded_rectangle([wx, wy, wx + 4, wy + h], radius=2, fill=(100, 116, 139, 255))
    draw.text((sx1 + 88, b3_y + 54), "0:14 • Walkie-Talkie Stream", fill=(100, 116, 139, 255), font=get_font(10, bold=True))
    
    # Quick Action Card in Middle: Peer Stats
    c_stat_y = b3_y + b3_h + 24
    c_stat_h = 96
    draw.rounded_rectangle([sx1 + 20, c_stat_y, sx2 - 20, c_stat_y + c_stat_h], radius=16, fill=(248, 250, 252, 255), outline=(226, 232, 240, 255), width=1)
    draw.text((sx1 + 34, c_stat_y + 14), "MESH CONNECTION METRICS", fill=(100, 116, 139, 255), font=get_font(10, bold=True))
    
    # Metric 1
    draw.text((sx1 + 34, c_stat_y + 36), "0.3 ms", fill=(15, 23, 42, 255), font=get_font(18, bold=True))
    draw.text((sx1 + 34, c_stat_y + 62), "Roundtrip Latency", fill=(100, 116, 139, 255), font=get_font(11, bold=False))
    
    # Metric 2
    draw.text((sx1 + 160, c_stat_y + 36), "86.4 MB/s", fill=(14, 165, 233, 255), font=get_font(18, bold=True))
    draw.text((sx1 + 160, c_stat_y + 62), "Direct Bandwidth", fill=(100, 116, 139, 255), font=get_font(11, bold=False))
    
    # Metric 3
    draw.text((sx1 + 286, c_stat_y + 36), "0% Loss", fill=(16, 185, 129, 255), font=get_font(18, bold=True))
    draw.text((sx1 + 286, c_stat_y + 62), "TCP Reliability", fill=(100, 116, 139, 255), font=get_font(11, bold=False))
    
    # Walkie-Talkie Hold to Talk Big Interactive Button
    ptt_y = c_stat_y + c_stat_h + 28
    ptt_h = 100
    draw.rounded_rectangle([sx1 + 20, ptt_y, sx2 - 20, ptt_y + ptt_h], radius=24, fill=(238, 242, 255, 255), outline=(199, 210, 254, 255), width=1)
    
    # Mic icon circle
    mic_cx = sx1 + 70
    mic_cy = ptt_y + 50
    draw.ellipse([mic_cx - 24, mic_cy - 24, mic_cx + 24, mic_cy + 24], fill=(79, 70, 229, 255))
    # mic pill
    draw.rounded_rectangle([mic_cx - 5, mic_cy - 12, mic_cx + 5, mic_cy + 4], radius=4, fill=(255, 255, 255, 255))
    draw.arc([mic_cx - 8, mic_cy - 6, mic_cx + 8, mic_cy + 8], 0, 180, fill=(255, 255, 255, 255), width=2)
    draw.line([(mic_cx, mic_cy + 8), (mic_cx, mic_cy + 13)], fill=(255, 255, 255, 255), width=2)
    
    draw.text((sx1 + 110, ptt_y + 28), "Push To Talk (Walkie-Talkie)", fill=(49, 46, 129, 255), font=get_font(15, bold=True))
    draw.text((sx1 + 110, ptt_y + 52), "Hold to broadcast real-time audio chunk", fill=(99, 102, 241, 255), font=get_font(11, bold=False))
    
    # Bottom Input Bar
    bar_y = sy2 - 62
    draw.rounded_rectangle([sx1 + 16, bar_y, sx2 - 16, bar_y + 48], radius=24, fill=(241, 245, 249, 255), outline=(226, 232, 240, 255), width=1)
    draw.text((sx1 + 36, bar_y + 15), "Type an encrypted peer message...", fill=(148, 163, 184, 255), font=f_p)
    # Send button
    draw.ellipse([sx2 - 58, bar_y + 6, sx2 - 24, bar_y + 40], fill=(14, 165, 233, 255))
    draw.polygon([(sx2 - 46, bar_y + 16), (sx2 - 32, bar_y + 23), (sx2 - 46, bar_y + 30)], fill=(255, 255, 255, 255))
    
    return im.convert("RGB")

if __name__ == "__main__":
    os.makedirs("assets/playstore", exist_ok=True)
    ss5 = generate_ss5_browser_drop()
    ss5.save("assets/playstore/screenshot_5_browser_drop.png", "PNG", quality=95)
    print("Saved assets/playstore/screenshot_5_browser_drop.png")
    
    ss6 = generate_ss6_walkie_talkie()
    ss6.save("assets/playstore/screenshot_6_walkie_talkie.png", "PNG", quality=95)
    print("Saved assets/playstore/screenshot_6_walkie_talkie.png")
