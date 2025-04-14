# poc-cloudfront_vpc_origin_internal_alb

## 概要
CloudFrontのVPC Originを試しました。Originとして、ALBをつけています。

## ディレクトリ構成

```
.
└── terraform
    ├── main.tf                     # mainファイル
    ├── network.tf                  # VPC, subnetの定義
    ├── acm.tf                      # 証明書及び認証用のCNAMEレコード
    ├── alb.tf                      # ALBの定義
    ├── cloudfront.tf               # CloudFrontの定義
    ├── route53.tf                  # Aレコード
    ├── variables.tf                # 変数定義
    ├── data.tf                     # 読み込み変数
    ├── outputs.tf                  # 出力定義
    └── container_definitions.json  # アプリの設定ファイル
```

## 使い方

デプロイをする。
```
# 独自ドメインを変数に設定します。
export TF_VAR_domain_name="<独自ドメイン>"

# デプロイします。
terraform init
terraform apply
```
