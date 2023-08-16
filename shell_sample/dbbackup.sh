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
find ${LOG_FULL_DIR} -type f | xargs chmod 644
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
    EXIT_CODE=${?}
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
    EXIT_CODE=${?}
    if [ ${EXIT_CODE} -ne 0 ]; then
      echo "exit_code:${EXIT_CODE} 3世代以降のDBバックアップ削除処理エラー　エラー対象${dbbackup_path}/${dbbackup_dir_array[$i]}"
      exit ${EXIT_CODE}
    fi
  fi
done

#####
# DBバックアップ
#####
echo "== DBバックアップ処理"
echo "mkdir ${dbbackup_path}/${now_date}"
mkdir ${dbbackup_path}/${now_date}
chmod 755 ${dbbackup_path}/${now_date}

#DBバックアップ実行
PGPASSWORD=${db_pass} pg_basebackup -D ${dbbackup_path}/${now_date} -h localhost -w -Ft -z -Xs -P -U postgres
EXIT_CODE=${?}
if [ ${EXIT_CODE} -ne 0 ]; then
  echo "exit_code:${EXIT_CODE} DBバックアップ実行処理エラー"
  exit ${EXIT_CODE}
fi
find ${dbbackup_path}/${now_date} -type f | xargs chmod 600

#####
# WALログ削除
#####
echo "== WALログ削除処理"
#WALログの.backupファイルリストをファイル作成日が新しい順で取得
archive_log_file_array=($(ls -lt ${archive_log_path}/*.backup | head | awk '{print $9}'))
for i in "${!archive_log_file_array[@]}"
do
  #3世代目の.backupファイルの時（配列3番目）WALログ削除コマンドを実行
  if [ 2 -eq ${i} ]; then
    #${archive_log_file_array[i]:23　：プルパスから23文字目以降のファイル名を抽出
    /usr/pgsql-11/bin/pg_archivecleanup ${archive_log_path} ${archive_log_file_array[i]:23}
    EXIT_CODE=${?}
    if [ ${EXIT_CODE} -ne 0 ]; then
      echo "exit_code:${EXIT_CODE} WALログ削除コマンド実行エラー"
      exit ${EXIT_CODE}
    fi
  fi
  #WALログ削除コマンドで削除されない3世代以降（配列の3番目以降）の.backupファイルを削除する
  if [ 2 -le ${i} ]; then
    rm -f ${archive_log_file_array[i]}
    EXIT_CODE=${?}
    if [ ${EXIT_CODE} -ne 0 ]; then
      echo "exit_code:${EXIT_CODE} WALログの.backupファイル削除処理エラー　エラー対象${archive_log_file_array[i]}"
      exit ${EXIT_CODE}
    fi
  fi
done

#####
# 1か月前の古いシェルログ削除
#####
echo "== 1か月前の古いシェルログ削除処理"
# find パス -type d ：パス内のディレクトリを検索
# -regextype posix-basic -regex ： findコマンドで正規表現検索するときのオプション
# find ~ | while 変数名 ：検索条件に合致したディレクトリ数分、do~done内の処理をループさせる。full_dir_nameはプルパス
find ${shell_log_base_path} -type d -regextype posix-basic -regex ".*log/[0-9]\{14\}" | while read full_dir_name
do
  #18文字目から31文字目まで切り取って変数に格納
  dir_name_date=`echo ${full_dir_name} | cut -c 18-32`
  #YYYYMMDDHHMMSS < 1か月前の日時　の場合ディレクトリを削除
  if [ ${dir_name_date} -lt ${month_ago_date} ]; then
    rm -rf ${full_dir_name}
    EXIT_CODE=${?}
    if [ ${EXIT_CODE} -ne 0 ]; then
      echo "exit_code:${EXIT_CODE} シェルログ削除処理エラー　エラー対象${full_dir_name}"
      exit ${EXIT_CODE}
    fi
  fi
done

#####
# シェル実行後確認
#####
echo "== シェル実行後確認"
echo "DBバックアップディレクトリの確認"
echo "ls -l ${dbbackup_path}"
ls -l ${dbbackup_path}
echo "アーカイブログディレクトリの確認"
echo "ls -l ${archive_log_path}"
ls -l ${archive_log_path}
echo "シェルログディレクトリの確認"
echo "ls -l ${shell_log_base_path}"
ls -l ${shell_log_base_path}

} &> ${LOG_NAME}
