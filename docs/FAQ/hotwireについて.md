edit_tenant_stay_room_bed_pathに対するturbo_frameは、どのように動く？


現在の実装では、「編集」リンクを押すとBed編集フォームだけがRoom編集画面内へ読み込まれます。

  リンクは次のようになっています。

  <%= link_to "編集",
              edit_tenant_stay_room_bed_path(listing, room, bed),
              data: { turbo_frame: "stay-bed-form" } %>

  Room編集画面には、受け皿となるTurbo Frameがあります。

  <%= turbo_frame_tag "stay-bed-form" %>

  クリック時の流れは次のとおりです。

  「編集」をクリック
    ↓
  GET /tenant/stays/:stay_id/rooms/:room_id/beds/:id/edit
    ↓
  BedsController#edit
    ↓
  beds/edit.html.erbを返す
    ↓
  レスポンス内の<turbo-frame id="stay-bed-form">を抽出
    ↓
  Room編集画面の同じIDのFrameだけを置換

  beds/edit.html.erbは次の構造です。

  <%= turbo_frame_tag "stay-bed-form" do %>
    <%= render "form", ... %>
  <% end %>

  したがって、ページ全体は遷移せず、ベッド一覧の上に編集フォームが表示されます。

  更新時はフォームからPATCHが送られます。

  PATCH /tenant/stays/:stay_id/rooms/:room_id/beds/:id

  更新成功時、ControllerはTurbo Streamを返します。

  turbo_stream.replace(
    "stay-beds-section",
    partial: "tenant/stay_management/beds/section",
    locals: { listing: @listing, room: @room }
  )

  これにより、フォームだけでなくBed管理セクション全体が再描画されます。

  <turbo-frame id="stay-beds-section">
    ベッド件数
    追加フォームの受け皿
    ベッド一覧
  </turbo-frame>

  結果として：

  - 更新後の値が一覧へ反映される
  - 編集フォームが閉じる
  - ベッド件数も更新される
  - Room編集フォームの入力内容やページ全体は維持される

  注意点として、stay-bed-formはstay-beds-sectionの内側にあります。更新成功時に親Frame全体を置換することで、子Frameの編集フォームも同時に初期状態へ戻る仕組みで
  す。


  ****************

  その仕組みもhotwireに含まれる？何をhotwireというのかよくわからない


• はい。その仕組み全体がHotwireに含まれます。

  Hotwireは、JavaScriptを大量に書かず、サーバーが返すHTMLで画面の一部を更新するための仕組みの総称です。

  Hotwireは主に次の3要素で構成されます。

   要素             役割
  ━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Turbo Drive      通常の画面遷移を高速化する
  ───────────────  ────────────────────────────────────────
   Turbo Frames     ページの特定領域だけを遷移・置換する
  ───────────────  ────────────────────────────────────────
   Turbo Streams    HTML要素の追加・置換・削除を指示する
  ───────────────  ────────────────────────────────────────
   Stimulus         JavaScriptが必要な細かな操作を実装する

  今回のBed編集では、Turbo FramesとTurbo Streamsを使っています。

  ### Turbo Frame

  編集リンクには更新対象のFrameを指定しています。

  data: { turbo_frame: "stay-bed-form" }

  ページ側には同じIDの受け皿があります。

  <%= turbo_frame_tag "stay-bed-form" %>

  編集リンクを押すと、レスポンス全体から同じIDのFrameだけが抜き出され、その領域へ表示されます。

  通常の遷移
  ページ全体 → ページ全体を置換

  Turbo Frame
  指定した領域 → 指定した領域だけを置換

  ### Turbo Stream

  Bedの更新成功時には、Controllerが次の命令を返します。

  turbo_stream.replace(
    "stay-beds-section",
    partial: "tenant/stay_management/beds/section",
    locals: { listing: @listing, room: @room }
  )

  ブラウザへ返されるHTMLは、概ね次の形です。

  <turbo-stream action="replace" target="stay-beds-section">
    <template>
      <!-- 更新後のBed管理セクション -->
    </template>
  </turbo-stream>

  Turboがこれを解釈して、対象部分だけを置換します。

  ### Stimulusとの違い

  Turboだけでは扱いにくいブラウザ上の操作にStimulusを使います。

  例えば：

  - モーダルを開閉する
  - 選択値に応じて入力欄を表示する
  - 文字数をリアルタイム表示する
  - ドラッグ＆ドロップする
  - フォーカスを制御する

  今回のBed編集は、サーバーからフォームを取得してHTMLを置換するだけなので、Stimulusは必要ありません。

  つまり今回の処理は次の構成です。

  Hotwire
  ├─ Turbo Frame
  │  └─ Bed編集フォームだけを読み込む
  └─ Turbo Stream
     └─ 更新後にBed管理セクションを再描画する

  「Hotwire」という名前の単一機能があるのではなく、TurboとStimulusを組み合わせた開発方式・ツール群をHotwireと呼びます。