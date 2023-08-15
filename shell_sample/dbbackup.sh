#!/bin/bash

#####
# 変数設定
#####
#現在日時
now_date=$(date '+%Y%m%d%H%M%S')
#一か月前の日付
month_ago_date=$(date --date '1 month ago' '+%Y%m%d%H%M%S')
#DBバックアップパス
dbbackup_path=/dbbackup/basebackup
#アーカイブログパス
archive_log_path=/dbbackup/archive_log
#シェルログbaseパス
shell_log_base_path=/shell_log
#出力シェルログパス
LOG_FULL_DIR=${shell_log_base_path}/${now_date}
#出力シェルログ名
LOG_NAME=${LOG_FULL_DIR}/dbbackup_${now_date}.log
