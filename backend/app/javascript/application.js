import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

// 既存のインラインJavaScriptをStimulusへ移行するまで、通常の画面遷移は維持する。
Turbo.session.drive = false
