import request from '@/utils/request'

// 查询分类列表
export function listCategory(query) {
  return request({
    url: '/agent/category/list',
    method: 'get',
    params: query
  })
}

// 查询分类树
export function treeCategory() {
  return request({
    url: '/agent/category/tree',
    method: 'get'
  })
}

// 查询分类详细
export function getCategory(categoryId) {
  return request({
    url: '/agent/category/' + categoryId,
    method: 'get'
  })
}

// 新增分类
export function addCategory(data) {
  return request({
    url: '/agent/category',
    method: 'post',
    data: data
  })
}

// 修改分类
export function updateCategory(data) {
  return request({
    url: '/agent/category',
    method: 'put',
    data: data
  })
}

// 删除分类
export function delCategory(categoryId) {
  return request({
    url: '/agent/category/' + categoryId,
    method: 'delete'
  })
}
