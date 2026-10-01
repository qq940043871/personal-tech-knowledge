<template>
  <div class="app-container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="mb8">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-icon" style="background:#67C23A"><i class="el-icon-s-data" /></div>
            <div class="stat-info">
              <div class="stat-title">今日调用次数</div>
              <div class="stat-value">{{ stats.todayCount || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-icon" style="background:#409EFF"><i class="el-icon-coin" /></div>
            <div class="stat-info">
              <div class="stat-title">今日Token消耗</div>
              <div class="stat-value">{{ formatNumber(stats.todayTokens) }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-icon" style="background:#E6A23C"><i class="el-icon-time" /></div>
            <div class="stat-info">
              <div class="stat-title">平均耗时(ms)</div>
              <div class="stat-value">{{ stats.avgDuration || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-icon" style="background:#F56C6C"><i class="el-icon-error" /></div>
            <div class="stat-info">
              <div class="stat-title">失败率</div>
              <div class="stat-value">{{ stats.failRate || '0%' }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 搜索区域 -->
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch">
      <el-form-item label="智能体" prop="agentId">
        <el-select v-model="queryParams.agentId" placeholder="请选择智能体" clearable style="width:200px">
          <el-option v-for="item in agentOptions" :key="item.agentId" :label="item.agentName" :value="item.agentId" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="请选择状态" clearable>
          <el-option label="成功" value="success" />
          <el-option label="失败" value="failed" />
          <el-option label="超时" value="timeout" />
        </el-select>
      </el-form-item>
      <el-form-item label="时间范围">
        <el-date-picker v-model="dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <!-- 数据表格 -->
    <el-table v-loading="loading" :data="logList">
      <el-table-column label="ID" align="center" prop="logId" width="70" />
      <el-table-column label="智能体" align="center" prop="agentId" width="120">
        <template slot-scope="scope">{{ getAgentName(scope.row.agentId) }}</template>
      </el-table-column>
      <el-table-column label="用户ID" align="center" prop="userId" width="80" />
      <el-table-column label="输入内容" align="left" prop="inputText" show-overflow-tooltip>
        <template slot-scope="scope">
          <el-tooltip :content="scope.row.inputText" placement="top">
            <span>{{ scope.row.inputText ? scope.row.inputText.substring(0, 50) + (scope.row.inputText.length > 50 ? '...' : '') : '-' }}</span>
          </el-tooltip>
        </template>
      </el-table-column>
      <el-table-column label="输出内容" align="left" prop="outputText" show-overflow-tooltip>
        <template slot-scope="scope">
          <el-tooltip :content="scope.row.outputText" placement="top">
            <span>{{ scope.row.outputText ? scope.row.outputText.substring(0, 50) + (scope.row.outputText.length > 50 ? '...' : '') : '-' }}</span>
          </el-tooltip>
        </template>
      </el-table-column>
      <el-table-column label="Token" align="center" prop="tokensUsed" width="80" />
      <el-table-column label="耗时(ms)" align="center" prop="durationMs" width="90" />
      <el-table-column label="状态" align="center" prop="status" width="80">
        <template slot-scope="scope">
          <el-tag :type="statusTag(scope.row.status)" size="small">
            {{ statusLabel(scope.row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="创建时间" align="center" prop="createTime" width="160">
        <template slot-scope="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width" width="100">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-view" @click="handleView(scope.row)">查看</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNum" :limit.sync="queryParams.pageSize" @pagination="getList" />

    <!-- 详情对话框 -->
    <el-dialog title="日志详情" :visible.sync="open" width="800px" append-to-body>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="日志ID">{{ form.logId }}</el-descriptions-item>
        <el-descriptions-item label="智能体">{{ getAgentName(form.agentId) }}</el-descriptions-item>
        <el-descriptions-item label="用户ID">{{ form.userId }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ parseTime(form.createTime) }}</el-descriptions-item>
        <el-descriptions-item label="Token消耗">{{ form.tokensUsed }}</el-descriptions-item>
        <el-descriptions-item label="耗时(ms)">{{ form.durationMs }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTag(form.status)">{{ statusLabel(form.status) }}</el-tag>
        </el-descriptions-item>
      </el-descriptions>
      <div style="margin-top:20px">
        <div class="detail-label">输入内容：</div>
        <el-input v-model="form.inputText" type="textarea" :rows="5" readonly />
      </div>
      <div style="margin-top:20px">
        <div class="detail-label">输出内容：</div>
        <el-input v-model="form.outputText" type="textarea" :rows="5" readonly />
      </div>
      <div v-if="form.errorMsg" style="margin-top:20px">
        <div class="detail-label" style="color:#F56C6C">错误信息：</div>
        <el-input v-model="form.errorMsg" type="textarea" :rows="3" readonly style="color:#F56C6C" />
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listLog, getLog, getLogStats } from '@/api/agent/log'
import { listAgent } from '@/api/agent/info'

export default {
  name: 'AgentUsageLog',
  data() {
    return {
      loading: false,
      showSearch: true,
      total: 0,
      logList: [],
      agentOptions: [],
      stats: {},
      dateRange: [],
      open: false,
      form: {},
      queryParams: {
        pageNum: 1,
        pageSize: 10,
        agentId: null,
        status: null
      }
    }
  },
  created() {
    this.getList()
    this.getAgentOptions()
    this.getStats()
  },
  methods: {
    getList() {
      this.loading = true
      const params = this.addDateRange(this.queryParams, this.dateRange)
      listLog(params).then(response => {
        this.logList = response.rows
        this.total = response.total
        this.loading = false
      })
    },
    getAgentOptions() {
      listAgent({ pageSize: 1000 }).then(response => {
        this.agentOptions = response.rows
      })
    },
    getAgentName(agentId) {
      const agent = this.agentOptions.find(a => a.agentId === agentId)
      return agent ? agent.agentName : agentId
    },
    getStats() {
      getLogStats().then(response => {
        this.stats = response.data || {}
      })
    },
    statusLabel(status) {
      const map = { success: '成功', failed: '失败', timeout: '超时' }
      return map[status] || status
    },
    statusTag(status) {
      const map = { success: 'success', failed: 'danger', timeout: 'warning' }
      return map[status] || 'info'
    },
    formatNumber(num) {
      if (!num) return 0
      return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')
    },
    handleQuery() { this.queryParams.pageNum = 1; this.getList() },
    resetQuery() { this.resetForm('queryForm'); this.dateRange = []; this.handleQuery() },
    handleView(row) {
      getLog(row.logId).then(response => {
        this.form = response.data
        this.open = true
      })
    }
  }
}
</script>

<style scoped>
.stat-item { display: flex; align-items: center; }
.stat-icon { width: 50px; height: 50px; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 24px; margin-right: 15px; }
.stat-info { flex: 1; }
.stat-title { font-size: 14px; color: #909399; margin-bottom: 5px; }
.stat-value { font-size: 24px; font-weight: bold; color: #303133; }
.detail-label { font-size: 14px; color: #606266; margin-bottom: 8px; font-weight: 500; }
</style>
