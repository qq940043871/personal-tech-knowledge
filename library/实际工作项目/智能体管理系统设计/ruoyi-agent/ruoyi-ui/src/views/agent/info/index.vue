<template>
  <div class="app-container">
    <!-- 搜索区域 -->
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch">
      <el-form-item label="智能体名称" prop="agentName">
        <el-input v-model="queryParams.agentName" placeholder="请输入智能体名称" clearable @keyup.enter.native="handleQuery" />
      </el-form-item>
      <el-form-item label="类型" prop="agentType">
        <el-select v-model="queryParams.agentType" placeholder="请选择类型" clearable>
          <el-option v-for="dict in dict.type.agent_type" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="请选择状态" clearable>
          <el-option label="正常" value="0" />
          <el-option label="停用" value="1" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 操作按钮 -->
    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="el-icon-plus" size="mini" @click="handleAdd" v-hasPermi="['agent:info:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="success" plain icon="el-icon-edit" size="mini" :disabled="single" @click="handleUpdate" v-hasPermi="['agent:info:edit']">修改</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="el-icon-delete" size="mini" :disabled="multiple" @click="handleDelete" v-hasPermi="['agent:info:remove']">删除</el-button>
      </el-col>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <!-- 数据表格 -->
    <el-table v-loading="loading" :data="agentList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column label="ID" align="center" prop="agentId" width="80" />
      <el-table-column label="头像" align="center" width="70">
        <template slot-scope="scope">
          <el-avatar :size="36" :src="scope.row.avatarUrl" icon="el-icon-user-solid" />
        </template>
      </el-table-column>
      <el-table-column label="智能体名称" align="center" prop="agentName" />
      <el-table-column label="类型" align="center" prop="agentType" width="100">
        <template slot-scope="scope">
          <el-tag :type="agentTypeTag(scope.row.agentType)" size="small">
            {{ agentTypeLabel(scope.row.agentType) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="关联模型" align="center" prop="modelName" />
      <el-table-column label="温度" align="center" prop="temperature" width="80" />
      <el-table-column label="最大Token" align="center" prop="maxTokens" width="100" />
      <el-table-column label="是否公开" align="center" prop="isPublic" width="90">
        <template slot-scope="scope">
          <el-tag :type="scope.row.isPublic === '1' ? 'success' : 'info'" size="small">
            {{ scope.row.isPublic === '1' ? '公开' : '私有' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" align="center" prop="status" width="80">
        <template slot-scope="scope">
          <el-switch v-model="scope.row.status" active-value="0" inactive-value="1"
            @change="handleStatusChange(scope.row)" />
        </template>
      </el-table-column>
      <el-table-column label="创建时间" align="center" prop="createTime" width="160">
        <template slot-scope="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width" width="160">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)" v-hasPermi="['agent:info:edit']">修改</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="handleDelete(scope.row)" v-hasPermi="['agent:info:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNum" :limit.sync="queryParams.pageSize" @pagination="getList" />

    <!-- 新增/修改对话框 -->
    <el-dialog :title="title" :visible.sync="open" width="700px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="100px">
        <el-row>
          <el-col :span="12">
            <el-form-item label="智能体名称" prop="agentName">
              <el-input v-model="form.agentName" placeholder="请输入智能体名称" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="类型" prop="agentType">
              <el-select v-model="form.agentType" placeholder="请选择类型" style="width:100%">
                <el-option v-for="dict in dict.type.agent_type" :key="dict.value" :label="dict.label" :value="dict.value" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row>
          <el-col :span="12">
            <el-form-item label="关联模型" prop="modelName">
              <el-input v-model="form.modelName" placeholder="如：gpt-4o, qwen-max" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="头像URL" prop="avatarUrl">
              <el-input v-model="form.avatarUrl" placeholder="请输入头像URL" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row>
          <el-col :span="12">
            <el-form-item label="温度" prop="temperature">
              <el-input-number v-model="form.temperature" :min="0" :max="2" :step="0.1" :precision="2" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="最大Token" prop="maxTokens">
              <el-input-number v-model="form.maxTokens" :min="1" :max="128000" :step="1024" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="系统提示词" prop="systemPrompt">
          <el-input v-model="form.systemPrompt" type="textarea" :rows="5" placeholder="请输入系统提示词" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="2" placeholder="请输入描述" />
        </el-form-item>
        <el-row>
          <el-col :span="12">
            <el-form-item label="是否公开" prop="isPublic">
              <el-radio-group v-model="form.isPublic">
                <el-radio label="1">公开</el-radio>
                <el-radio label="0">私有</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态" prop="status">
              <el-radio-group v-model="form.status">
                <el-radio label="0">正常</el-radio>
                <el-radio label="1">停用</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="cancel">取 消</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listAgent, getAgent, addAgent, updateAgent, delAgent } from '@/api/agent/info'

export default {
  name: 'AgentInfo',
  dicts: ['agent_type'],
  data() {
    return {
      loading: false,
      showSearch: true,
      single: true,
      multiple: true,
      total: 0,
      agentList: [],
      title: '',
      open: false,
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        agentName: null,
        agentType: null,
        status: null
      },
      form: {},
      rules: {
        agentName: [{ required: true, message: '智能体名称不能为空', trigger: 'blur' }],
        agentType: [{ required: true, message: '请选择类型', trigger: 'change' }]
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    getList() {
      this.loading = true
      listAgent(this.queryParams).then(response => {
        this.agentList = response.rows
        this.total = response.total
        this.loading = false
      })
    },
    agentTypeLabel(type) {
      const map = { chat: '对话', text2img: '文生图', code: '代码', embedding: '嵌入', agent: '智能体' }
      return map[type] || type
    },
    agentTypeTag(type) {
      const map = { chat: 'primary', text2img: '', code: 'success', embedding: 'warning', agent: 'danger' }
      return map[type] || 'info'
    },
    handleStatusChange(row) {
      const text = row.status === '0' ? '启用' : '停用'
      this.$confirm('确认要' + text + '【' + row.agentName + '】吗?', '警告', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(() => {
        updateAgent({ agentId: row.agentId, status: row.status }).then(() => {
          this.$modal.msgSuccess(text + '成功')
        })
      }).catch(() => {
        row.status = row.status === '0' ? '1' : '0'
      })
    },
    handleQuery() { this.queryParams.pageNum = 1; this.getList() },
    resetQuery() { this.resetForm('queryForm'); this.handleQuery() },
    handleSelectionChange(selection) {
      this.single = selection.length !== 1
      this.multiple = !selection.length
      this.ids = selection.map(item => item.agentId)
    },
    reset() {
      this.form = { agentType: 'chat', temperature: 0.7, maxTokens: 4096, status: '0', isPublic: '1' }
      this.resetForm('form')
    },
    handleAdd() {
      this.reset()
      this.open = true
      this.title = '新增智能体'
    },
    handleUpdate(row) {
      this.reset()
      const agentId = row.agentId || this.ids[0]
      getAgent(agentId).then(response => {
        this.form = response.data
        this.open = true
        this.title = '修改智能体'
      })
    },
    submitForm() {
      this.$refs['form'].validate(valid => {
        if (valid) {
          if (this.form.agentId != null) {
            updateAgent(this.form).then(() => {
              this.$modal.msgSuccess('修改成功')
              this.open = false
              this.getList()
            })
          } else {
            addAgent(this.form).then(() => {
              this.$modal.msgSuccess('新增成功')
              this.open = false
              this.getList()
            })
          }
        }
      })
    },
    cancel() { this.open = false; this.reset() },
    handleDelete(row) {
      const agentIds = row.agentId || this.ids
      this.$confirm('是否确认删除智能体编号为【' + agentIds + '】的数据项?', '警告', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(() => {
        return delAgent(agentIds)
      }).then(() => {
        this.getList()
        this.$modal.msgSuccess('删除成功')
      })
    }
  }
}
</script>
