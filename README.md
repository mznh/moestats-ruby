# moestats-ruby
Sharlさんの https://github.com/sharl/moestats のコア部分だけRubyに移植してロギングするようにしたもの

結果は定期的にGCSへ転送するようにしていて、フロントエンドはDataPortalで提供している。→ https://www.mznh.jp/moe/stats/


## todo
~~今これVPS上で動かしてるけど、CloudFunctionとかに移したいね~~

GCPに移行して試験運用中

## インフラ構成
```
 Cloud Scheduler -> Cloud Pub/Sub -> Cloud Functions -> Cloud Storage -> LookerStudio
```


## GCSのディレクトリ構造

```
├── composed <------- LookerStudioが参照するディレクトリ
│   ├── 202404.csv
│   └── 202405.csv
│             :
├── raw <------------ データ取得直後のファイルが置かれる
└── header.csv <----- 月次ファイル初期化用のヘッダーファイル
```
