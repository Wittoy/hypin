VERSION="1.1.3"
DEBUG_FLAG=false
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

var_brand="`grep_prop ro.product.brand`"
var_version="`grep_prop ro.build.version.release`"

print_modname() {
  ui_print "**************************************"
  ui_print "             幻影Pin驱动 "
  ui_print "-----------------------------"
  ui_print "- 推荐安装幻影Pin提示欲刷入的驱动 "
  ui_print "- 小米推荐驱动6，红米推荐驱动1/3/9 "
  ui_print "- 华为荣耀/魅族推荐驱动3，OPPO/VIVO推荐驱动7 "
  ui_print "- 三星推荐驱动8，类原生(接近也行)推荐驱动4 "
  ui_print "- 注：先以幻影Pin提示欲刷入的驱动为主，再尝试上面的推荐选择！ "
  ui_print "-----------------------------"
  ui_print "  (\__/)"
  ui_print "  (•ㅅ•) "
  ui_print "  /づ 当前设备为$var_brand丨Android $var_version"
  ui_print "**************************************"
}

initmods()
{
  mod_name=""
  mod_install_info=""
  mod_select_yes_text=""
  mod_select_yes_desc=""
  mod_select_no_text=""
  mod_select_no_desc=""
  mod_require_device=""
  mod_require_version=""
  INSTALLED_FUNC="`trim $INSTALLED_FUNC`"
  MOD_SKIP_INSTALL=false
  cd $TMPDIR/mods
}

keytest() {
  ui_print "- 音量键测试 -"
  ui_print "   请按下 [音量+] 键："
  ui_print "   无反应或传统模式无法正确安装时，请触摸一下屏幕后继续"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $TMPDIR/events) || return 1
  return 0
}

chooseport() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $TMPDIR/events
    if (`cat $TMPDIR/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $TMPDIR/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $KEYCHECK
  $KEYCHECK
  SEL=$?
  $DEBUG_FLAG && ui_print "  DEBUG: chooseportold: $1,$SEL"
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    abort "   未检测到音量键!"
  fi
}

on_install() {

  # 解压文件
  unzip -o "$ZIPFILE" 'mods/*' -d "$TMPDIR/" >&2
  # 公用函数
  source $TMPDIR/util_funcs.sh

  # Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
  KEYCHECK=$TMPDIR/keycheck
  chmod 755 $KEYCHECK
  # 测试音量键
  if keytest; then
    VOLKEY_FUNC=chooseport
    ui_print "*******************************"
  else
    VOLKEY_FUNC=chooseportold
    ui_print "*******************************"
    ui_print "- 检测到遗留设备！使用旧的 keycheck 方案 -"
    ui_print "- 进行音量键录入 -"
    ui_print "   录入：请按下 [音量+] 键："
    $VOLKEY_FUNC "UP"
    ui_print "   已录入 [音量+] 键。"
    ui_print "   录入：请按下 [音量-] 键："
    $VOLKEY_FUNC "DOWN"
    ui_print "   已录入 [音量-] 键。"
  ui_print "*******************************"
  fi

  REPLACE=""

  MODS_SELECTED_YES=""
  MODS_SELECTED_NO=""
  
  initmods
  for MOD in $(ls)
  do
    if [ -f $MOD/mod_info.sh ]; then
      MOD_FILES_DIR="$TMPDIR/mods/$MOD/files"
      source $MOD/mod_info.sh
      $DEBUG_FLAG && ui_print "  DEBUG: load $MOD"
      $DEBUG_FLAG && ui_print "  DEBUG: mod's name: $mod_name"
      $DEBUG_FLAG && ui_print "  DEBUG: mod's device requirement: $mod_require_device"
      $DEBUG_FLAG && ui_print "  DEBUG: mod's version requirement: $mod_require_version"
      if [ -z $mod_require_device ]; then
        mod_require_device=$var_device
        $DEBUG_FLAG && ui_print "  DEBUG: replace mod's device requirement: $mod_require_device"
      fi
      if [ -z $mod_require_version ]; then
        mod_require_version=$var_version
        $DEBUG_FLAG && ui_print "  DEBUG: replace mod's version requirement: $mod_require_version"
      fi
      if $MOD_SKIP_INSTALL ; then
        ui_print "  跳过[$mod_name]安装"
        initmods
        continue
      fi
      if [ "`echo $var_version | egrep $mod_require_version`" = "" ]; then
        ui_print "   [$mod_name]不支持你的系统版本。"
      else
        ui_print "  [$mod_name]安装"
        ui_print "  - 介绍: $mod_install_desc"
        ui_print "  - 请按音量键选择$mod_install_info -"
        ui_print "   [音量+]：$mod_select_yes_text"
        ui_print "   [音量-]：$mod_select_no_text"
        if $VOLKEY_FUNC; then
          ui_print "   已选择[$mod_select_yes_text]。"
          mod_install_yes
          run_result=$?
          if [ $run_result -eq 0 ]; then
            MODS_SELECTED_YES="$MODS_SELECTED_YES ($MOD)"
            INSTALLED_FUNC="$mod_name $INSTALLED_FUNC"
          else
            ui_print "   失败。错误: $run_result"
          fi
        else
          ui_print "   已选择[$mod_select_no_text]。"
          mod_install_no
          run_result=$?
          if [ $run_result -eq 0 ]; then
            MODS_SELECTED_NO="$MODS_SELECTED_NO ($MOD)"
            INSTALLED_FUNC="$mod_select_no_desc $INSTALLED_FUNC"
          else
            ui_print "   失败。错误: $run_result"
          fi
        fi
      fi
    else
      $DEBUG_FLAG && ui_print "  DEBUG: could not found $MOD's mod_info.sh"
    fi
    initmods
  done

  if [ -z "$INSTALLED_FUNC" ]; then
    ui_print "未安装任何功能 即将退出安装..."
    rm -rf $TMPDIR
    exit 1
  fi

  echo "description=当前安装驱动为：$INSTALLED_FUNC" >> $TMPDIR/module.prop
}
