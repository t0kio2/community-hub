class Admin::HomeController < Admin::BaseController
  def index
    @articles = [
      { id: 1, title: "Rails 8の新機能について", content: "KamalやSolid Adapterが標準搭載されました。" },
      { id: 2, title: "Hotwireの使い方入門", content: "Turbo Framesを使うと、非同期更新が超簡単になります！" }
    ]
  end
  
end
