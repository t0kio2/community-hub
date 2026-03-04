学習順序

- 基本把握: プロジェクト構成（src/routes/*, router.tsx, styles.css）と実行フロー（SSR→Hydrate）を俯瞰。
- ルーティング: createFileRoute の命名規約、/blog と blog.$slug.tsx を読んでパラメータ/Head設定を理解。
- データ取得: TanStack Query の基本（クエリ/ミューテーション、キャッシュ、無効化、prefetchQuery）。
- ルーター連携: ルートloaderでのフェッチと Query の併用、dehydrate/hydrate によるSSRデータ渡し。
- サーバ関数: Startのサーバ関数で安全にDB/外部APIへアクセスし、クライアントから型安全に呼ぶ。
- コンテンツ: content-collections.ts と allBlogs の生成・利用（MD/MDX→HTML/MDX）を理解。

実践課題（このリポで）

- 01 ルート追加: 既に /hello あり。/about を追加し Head メタを設定。
- 02 動的ルート: blog.$slug.tsx を読み、params.slug と allBlogs から記事表示を追う。
- 03 外部API読取: 仮のAPIをuseQueryで取得するルートを作成（エラー/ローディング表示含む）。
- 04 SSR連携: そのAPIをルートloaderでprefetchQuery→dehydrateし、クライアントでhydrate。
- 05 更新系: サーバ関数＋useMutationでフォーム送信→キャッシュ無効化、楽観的更新を体験。
- 06 例外処理: 404/エラー境界、notFound() 相当のハンドリングを追加。

見るべきコード

- ルート: src/routes/index.tsx, blog.index.tsx, blog.$slug.tsx, __root.tsx
- ルーター: src/router.tsx
- コンテンツ: content-collections.ts, content/blog/*, 生成物 /.content-collections/generated/*

便利ツール

- Devtools: 既に組み込み。画面右下のパネルで Router/Query の状態を可視化。
- 型ガイド: web/.content-collections/generated/index.d.ts の Blog 型を参照しつつ開発。

最小コード例（型安全なQuery）

- クエリ: useQuery({ queryKey: ['posts'], queryFn: fetcher })
- ルートloaderでSSR: await queryClient.prefetchQuery(...); return { dehydrated: dehydrate(queryClient) }

参考（公式ドキュメントの順に）

- TanStack Start（ルーティング/SSR/サーバ関数）
- TanStack Router（file-based routing, loaders, head）
- TanStack Query（キャッシュ、ミューテーション、SSR）