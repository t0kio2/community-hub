# 事始め
hello worldを返すエンドポイントを作ろう

```
GET /api/hello

{
  "message": "Hello World"
}
```

dockerコンテナに入り、以下を実行しコントローラ作成
```
rails generate controller api/hello
```

すると以下の2ファイルができた。
- api/app/controllers/api/hello_controller.rb
- api/test/controllers/api/hello_controller.rb

以下を書いていく
```
def index
  render json: { message: 'Hello World' }
end
```

続いて、ルーティングを定義
```
namespace :api do
  get 'hello', to: 'hello#index'
end
```

こうすると、GET /api/hello -> Api::HelloController#index が有効になる。