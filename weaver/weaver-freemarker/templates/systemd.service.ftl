[Unit]
Description=${description}
After=network.target

[Service]
Type=simple
User=${user}
Group=${group}
ExecStart=${exec_start}
Restart=${restart}
RestartSec=${restart_sec}
<#list environment?keys?sort as key>
Environment=${key}=${environment[key]}
</#list>

[Install]
WantedBy=multi-user.target
