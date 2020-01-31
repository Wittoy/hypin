mod_name="驱动5"
mod_install_desc="为设备安装$mod_name"
mod_install_info="是否安装$mod_name"
mod_select_yes_text="安装$mod_name"
# 按下[音量+]后加入module.prop的内容
mod_select_yes_desc="[$mod_select_yes_text]"
mod_select_no_text="不安装$mod_name"
mod_select_no_desc=" "
mod_require_device=" "
mod_require_version=" "

if [ "`check_mod_install`" = "yes" ]; then
MOD_SKIP_INSTALL=true
fi

mod_install_yes()
{
    mkdir -p $MODPATH/system/bin/
    cp -r $MOD_FILES_DIR/wpa_cli5 $MODPATH/system/bin/wpa_cli
    ui_print "  设置权限中..."
    set_perm_recursive  $MODPATH/system/bin/wpa_cli  0  0  0755  0755
    
    return 0
}

mod_install_no()
{
    return 0
}
