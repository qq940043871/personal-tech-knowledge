import request from '@/utils/request'

// 查询日志列表
export function listLog(query) {
  return request({
    url: '/agent/log/list',
    method: 'get',
    params: query
  })
}

// 查询日志详细
export function getLog(logId) {
  return request({
    url: '/agent/log/' + logId,
    method: 'get'
  })
}

// 查询日志统计
export function getLogStats() {
  return request({
    url: '/agent/log/stats',
    method: 'get'
  })
}
