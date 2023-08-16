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

#####
# ログファイル作成
#####
mkdir ${LOG_FULL_DIR}
touch ${LOG_NAME}
#シェルログディレクトリ配下のディレクトリを一括で権限775にし、ファイルを一括で権限644にする
find ${shell_log_base_path} -type d | xargs chmod 775
find ${LOG_FULL_DIR} -type f | xargs chmod 775
#以下{}内の処理について標準出力と標準エラー出力をログファイルに出力する。
{
echo "=="
echo "== DBバックアップ"
echo "=="

#####
# シェル実行前確認
#####
echo "== シェル実行前確認"
echo "DBバックアップディレクトリの確認"
echo "ls -l ${dbbackup_path}"
ls -l ${dbbackup_path}
echo "アーカイブログディレクトリの確認"
echo "ls -l ${archive_log_path}"
ls -l ${archive_log_path}
echo "シェルログディレクトリの確認"
echo "ls -l ${shell_log_base_path}"
ls -l ${shell_log_base_path}

#####
# opensslでDBパスワードを復号
#####
echo "== openssl　パスワード復号処理"
# パスワード復号コマンド「openssl enc -d <CipherType> -kfile <鍵ファイル> -in <暗号化済みパスワードファイル>」
db_pass=`openssl enc -d -aes-256-cbc -kfile /★★/db_secret -in /★★/encripted_db_password`
EXIT_CODE=${?}
if [ ${EXIT_CODE} -ne 0 ]; then
  echo "exit_code:${EXIT_CODE} DBパスワード復号処理エラー"
  exit ${EXIT_CODE}
fi

#####
# 空のDBバックアップディレクトリを削除する
#####
echo "== 空のDBバックアップディレクトリ削除処理"
#DBバックアップディレクトリを取得する
# ls -lt <パス>       ：<パス>配下のディレクトリとファイルを時刻によってソートしてリストする。
# grep '.[0-9]\{14\}' ：YYYYMMDDHHMMSS形式(数字14桁)のディレクトリを検索する
# awk '{print $9}'    ：ls -ltで出力される値の9番目の値(ファイル名)を出力する
dir_array=($(ls -lt ${dbbackup_path} | grep '.[0-9]\{14\}' | awk '{print $9}'))
for i in "${!dir_array[@]}"
do
  #空のディレクトリの場合ディレクトリを削除する
  if [ -z "$(ls -A ${dbbackup_path}/${dbbackup_dir_array[$i]})" ]; then
    echo "rm -rf ${dbbackup_path}/${dbbackup_dir_array[$i]}"
    rm -rf ${dbbackup_path}/${dbbackup_dir_array[$i]}
    if [ ${EXIT_CODE} -ne 0 ]; then
      echo "exit_code:${EXIT_CODE} 空のDBバックアップディレクトリ削除処理エラー　エラー対象${dbbackup_path}/${dbbackup_dir_array[$i]}"
      exit ${EXIT_CODE}
    fi
  fi
done

#####
# 3世代以降のDBバックアップを削除する
#####
echo "== 3世代以降のDBバックアップ削除処理"
dir_array=($(ls -lt ${dbbackup_path} | grep '.[0-9]\{14\}' | head | awk '{print $9}'))
for i in "${!dir_array[@]}"
do
  #配列の2番目以降のディレクトリを削除する
  if [ 1 -le ${i} ]; then
    echo "rm -rf ${dbbackup_path}/${dbbackup_dir_array[$i]}"
    rm -rf ${dbbackup_path}/${dbbackup_dir_array[$i]}
    if [ ${EXIT_CODE} -ne 0 ]; then
      echo "exit_code:${EXIT_CODE} 3世代以降のDBバックアップ削除処理エラー　エラー対象${dbbackup_path}/${dbbackup_dir_array[$i]}"
      exit ${EXIT_CODE}
    fi
  fi
done

#####
# 3世代以降のDBバックアップを削除する
#####

}
