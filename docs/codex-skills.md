# Codex Skills

このリポジトリでは、チームで共有したい Codex の作業ルールを `skills/` 配下に置く。

## 共有 skill

### `plan-doc-implement-test`

場所:

```text
skills/plan-doc-implement-test
```

目的:

- 実装前に計画や設計をドキュメントへ書く
- 実装する
- テストを書く
- 新しく追加するコメントやテストケース名は日本語で書く

## このプロジェクトでの使い方

リポジトリ内の `skills/` は、チームで共有するための置き場。

Codex の実行環境によっては、リポジトリ内の skill が自動検出されない場合がある。その場合は、プロンプトで skill のパスを明示する。

例:

```text
skills/plan-doc-implement-test のルールに従って、この機能を実装して。
```

短く指定する場合:

```text
$plan-doc-implement-test を使って、この機能を実装して。
```

ただし `$plan-doc-implement-test` で呼び出すには、Codex がこの skill を認識できる場所にインストールされている必要がある。

## 個人環境へインストールする場合

Codex が自動検出できる場所へコピーする。

```sh
mkdir -p ~/.codex/skills
cp -R skills/plan-doc-implement-test ~/.codex/skills/
```

コピー後、新しい Codex セッションで skill が利用できる。

更新済みの skill を反映したい場合は、コピー先を入れ替える。

```sh
rm -rf ~/.codex/skills/plan-doc-implement-test
cp -R skills/plan-doc-implement-test ~/.codex/skills/
```

## 実装依頼時のプロンプト例

新機能を実装する場合:

```text
skills/plan-doc-implement-test のルールに従って、tenant のスタッフ追加機能を実装して。
```

既存実装を修正する場合:

```text
skills/plan-doc-implement-test のルールに従って、admin の tenant 作成処理のバグを修正して。
```

テスト追加を依頼する場合:

```text
skills/plan-doc-implement-test のルールに従って、この controller のテストを追加して。
```

## skill が求める作業順序

`plan-doc-implement-test` は、Codex に以下の順序で作業させるための skill。

1. 関連コードと既存 docs を確認する
2. 実装前に計画/設計を `docs/` に書く、または既存 docs を更新する
3. 実装する
4. テストを書く
5. focused test を実行する
6. 変更ファイル、テストコマンド、結果を報告する

新しく追加するコメント、テストケース名、テスト説明は日本語で書く。

## 更新時の注意

- skill 本体は `skills/<skill-name>/SKILL.md` に書く
- UI 用メタデータは `skills/<skill-name>/agents/openai.yaml` に置く
- skill 内に README などの補助ドキュメントは増やさない
- 具体的な開発手順やプロジェクト運用の説明は `docs/` に置く
