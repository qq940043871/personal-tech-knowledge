import request from '@/utils/request'

// 查询智能体列表
export function listAgent(query) {
  return request({
    url: '/agent/info/list',
    method: 'get',
    params: query
  })
}

// 查询智能体详细
export function getAgent(agentId) {
  return request({
    url: '/agent/info/' + agentId,
    method: 'get'
  })
}

// 新增智能体
export function addAgent(data) {
  return request({
    url: '/agent/info',
    method: 'post',
    data: data
  })
}

// 修改智能体
export function updateAgent(data) {
  return request({
    url: '/agent/info',
    method: 'put',
    data: data
  })
}

// 删除智能体
export function delAgent(agentId) {
  return request({
    url: '/agent/info/' + agentId,
    method: 'delete'
  })
}
