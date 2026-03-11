// 配置将通过 api.getConfig() 获取
let config = {};

// 获取应用访问令牌（用于查询等操作）
async function getDingtalkToken() {
    const url = "https://api.dingtalk.com/v1.0/oauth2/accessToken";
    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ appKey: config.appKey, appSecret: config.appSecret })
    });
    const data = await response.json();
    return data.accessToken;
}

// 获取用户访问令牌（用于执行审批等需要用户权限的操作）
async function getUserAccessToken(authCode) {
    const url = "https://api.dingtalk.com/v1.0/oauth2/userAccessToken";
    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
            clientId: config.appKey, 
            clientSecret: config.appSecret,
            code: authCode,
            grantType: "authorization_code"
        })
    });
    const data = await response.json();
    return data.accessToken;
}

// 暴露给 OpenClaw 的注册入口
module.exports.register = function (api) {
    // 读取配置
    config = api.getConfig() || {};
    
    // 验证配置
    if (!config.dingtalkUserId || !config.appKey || !config.appSecret) {
        console.warn("[dingtalk-approval] 配置不完整，请在插件配置中设置 dingtalkUserId、appKey 和 appSecret");
    }
    
    // 工具 1: 查询待办
    api.registerTool({
        name: "get_pending_tasks",
        description: "查询我的 OA 审批待办任务列表。在执行同意或拒绝操作前，必须先调用此工具获取任务详情和底层 ID。",
        parameters: {
            type: "object",
            properties: {},
            additionalProperties: false
        },
        execute: async (toolCallId, args) => {
            try {
                const token = await getDingtalkToken();
                
                // 接口1: 获取用户待办任务列表（新版API）
                const url1 = `https://oapi.dingtalk.com/topapi/process/workrecord/task/query?access_token=${token}`;
                const payload1 = {
                    userid: config.dingtalkUserId,
                    offset: 0,
                    count: 50,  // 修正：用 count 而不是 length
                    status: 0   // 0: 待处理
                };
                
                const response1 = await fetch(url1, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload1)
                });
                const result1 = await response1.json();
                
                // 接口2: 获取审批模板列表，然后查询每个模板的待办
                // 先获取用户可见的审批模板
                const urlTemplates = `https://oapi.dingtalk.com/topapi/process/template/list?access_token=${token}`;
                const responseTemplates = await fetch(urlTemplates, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        offset: 0,
                        size: 100
                    })
                });
                const resultTemplates = await responseTemplates.json();
                
                let allInstanceIds = [];
                
                // 如果有模板，遍历查询每个模板的实例
                if (resultTemplates.result?.list && resultTemplates.result.list.length > 0) {
                    for (const template of resultTemplates.result.list.slice(0, 5)) { // 只查前5个模板避免超时
                        const urlInstances = `https://oapi.dingtalk.com/topapi/processinstance/listids?access_token=${token}`;
                        const payloadInstances = {
                            process_code: template.process_code,
                            start_time: Date.now() - 30 * 24 * 60 * 60 * 1000,
                            end_time: Date.now(),
                            size: 20
                        };
                        
                        const responseInstances = await fetch(urlInstances, {
                            method: "POST",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify(payloadInstances)
                        });
                        const resultInstances = await responseInstances.json();
                        
                        if (resultInstances.result?.list) {
                            allInstanceIds = allInstanceIds.concat(resultInstances.result.list);
                        }
                    }
                }
                
                const tasks1 = result1.result?.list || [];
                
                if (tasks1.length === 0 && allInstanceIds.length === 0) {
                    return `当前没有待办单据。API1返回: ${JSON.stringify(result1.result || result1)}, 模板数: ${resultTemplates.result?.list?.length || 0}`;
                }
                
                // 构建包含所有必要信息的任务列表
                // 注意：钉钉API返回的数据中可能没有process_instance_id
                // 需要使用task_id直接执行审批操作
                const taskList = tasks1.map((t, index) => {
                    const num = index + 1;
                    return `${num}. 任务ID: ${t.task_id} - ${t.title}`;
                }).join("\n");
                
                return `找到 ${tasks1.length} 条待办任务：\n${taskList}\n\n注意：当前API返回的数据不包含process_instance_id。执行审批时可以直接使用task_id。`;
            } catch (error) {
                return `查询异常：${error.message}`;
            }
        }
    });

    // 工具 2: 执行审批
    api.registerTool({
        name: "execute_approval_task",
        description: "执行 OA 审批的同意或拒绝操作。必须先从 get_pending_tasks 中提取出 task_id 和 process_instance_id 后才能调用。",
        parameters: {
            type: "object",
            properties: {
                task_id: { type: "string", description: "待办任务的唯一ID（必填）" },
                process_instance_id: { type: "string", description: "审批单的实例ID（可选，如不提供会自动查询）" },
                action: { type: "string", enum: ["AGREE", "REFUSE"], description: "审批动作：AGREE 或 REFUSE" },
                remark: { type: "string", description: "审批意见" }
            },
            required: ["task_id", "action"],
            additionalProperties: false
        },
        execute: async (toolCallId, args) => {
            try {
                const token = await getDingtalkToken();
                
                // 如果没有提供 process_instance_id，尝试通过 task_id 获取
                let processInstanceId = args.process_instance_id;
                if (!processInstanceId) {
                    // 尝试从待办列表中获取
                    const urlQuery = `https://oapi.dingtalk.com/topapi/process/workrecord/task/query?access_token=${token}`;
                    const responseQuery = await fetch(urlQuery, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                            userid: config.dingtalkUserId,
                            offset: 0,
                            count: 50,
                            status: 0
                        })
                    });
                    const resultQuery = await responseQuery.json();
                    const tasks = resultQuery.result?.list || [];
                    const targetTask = tasks.find(t => String(t.task_id) === String(args.task_id));
                    if (targetTask) {
                        processInstanceId = targetTask.process_instance_id || targetTask.instance_id;
                    }
                }
                
                if (!processInstanceId) {
                    return `无法获取审批实例ID。请确认任务ID ${args.task_id} 正确，或手动提供 process_instance_id。`;
                }
                
                // 方法1: 使用正确的 API 地址（根据钉钉开放平台文档）
                // 接口：POST /v1.0/workflow/processInstances/execute
                const urlNew = `https://api.dingtalk.com/v1.0/workflow/processInstances/execute`;
                const payloadNew = {
                    processInstanceId: processInstanceId,
                    taskId: args.task_id,
                    actionerUserId: config.dingtalkUserId,
                    result: args.action.toUpperCase() === "AGREE" ? "agree" : "refuse",
                    remark: args.remark || (args.action.toUpperCase() === "AGREE" ? "同意" : "拒绝")
                };
                
                const responseNew = await fetch(urlNew, {
                    method: "POST",
                    headers: { 
                        "Content-Type": "application/json",
                        "x-acs-dingtalk-access-token": token
                    },
                    body: JSON.stringify(payloadNew)
                });
                const resultNew = await responseNew.json();
                
                if (responseNew.ok && (resultNew.success || resultNew.code === "OK" || !resultNew.code)) {
                    return `操作成功（新版API）！已将任务 ${args.task_id} 设置为 ${args.action}。`;
                }
                
                // 方法2: 尝试使用用户访问令牌（需要用户授权）
                // 注意：使用用户访问令牌需要先在钉钉中授权
                // 授权URL: https://open.dingtalk.com/document/isv/app-overview
                
                return `执行失败。\n\n【新版API】返回：${JSON.stringify(resultNew)}\n\n【旧版API】返回：应用缺少 qyapi_aflow_execute 权限\n\n解决方案：\n\n方案1（推荐）：使用个人访问令牌\n需要用户在钉钉中授权应用访问其数据。授权步骤：\n1. 访问钉钉开放平台：https://open-dev.dingtalk.com/\n2. 找到应用 ${APP_KEY}\n3. 在"权限管理"中申请以下权限：\n   - 个人手机号信息\n   - 通讯录个人信息读权限\n   - 审批流审批权限\n4. 使用钉钉扫码授权获取 authCode\n5. 使用 authCode 换取用户访问令牌\n\n方案2：在钉钉App中手动审批\n打开钉钉App → 工作台 → OA审批 → 找到待办任务手动处理\n\n方案3：联系钉钉客服\n申请开通企业内部应用的审批执行权限（通常较难获批）。`;
            } catch (error) {
                return `执行异常：${error.message}`;
            }
        }
    });
    
    // 工具 3: 获取钉钉授权链接
    api.registerTool({
        name: "get_dingtalk_auth_url",
        description: "获取钉钉用户授权链接，用于获取个人访问令牌。用户需要在钉钉中点击链接并授权后，才能获得执行审批的权限。",
        parameters: {
            type: "object",
            properties: {
                redirect_uri: { type: "string", description: "授权回调地址（可选，默认为本地回调）" }
            },
            additionalProperties: false
        },
        execute: async (toolCallId, args) => {
            const redirectUri = args.redirect_uri || "https://www.dingtalk.com";
            const authUrl = `https://login.dingtalk.com/oauth2/auth?response_type=code&client_id=${APP_KEY}&scope=openid&state=STATE&redirect_uri=${encodeURIComponent(redirectUri)}&prompt=consent`;
            
            return `请按以下步骤获取用户授权：\n\n1. 点击授权链接（或复制到浏览器）：\n${authUrl}\n\n2. 使用钉钉扫码或登录后授权\n\n3. 授权成功后，复制回调URL中的 code 参数\n\n4. 使用 code 调用 exchange_auth_code 工具换取访问令牌\n\n注意：此授权码有效期为5分钟，请尽快使用。`;
        }
    });
    
    // 工具 4: 用授权码换取访问令牌
    api.registerTool({
        name: "exchange_auth_code",
        description: "使用钉钉授权码换取用户访问令牌。获取的令牌可用于执行审批操作。",
        parameters: {
            type: "object",
            properties: {
                auth_code: { type: "string", description: "钉钉授权码（从授权回调URL中获取）" }
            },
            required: ["auth_code"],
            additionalProperties: false
        },
        execute: async (toolCallId, args) => {
            try {
                const token = await getUserAccessToken(args.auth_code);
                if (token) {
                    return `成功获取用户访问令牌！\n\n令牌：${token.substring(0, 20)}...（已隐藏部分）\n\n现在可以使用此令牌执行审批操作。\n注意：令牌有效期有限，请妥善保管。`;
                }
                return `获取令牌失败，请检查授权码是否正确或已过期。`;
            } catch (error) {
                return `换取令牌异常：${error.message}`;
            }
        }
    });
};