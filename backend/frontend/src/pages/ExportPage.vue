<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useLogsStore } from '@/stores/logs'
import { useStudentsStore } from '@/stores/students'
import { useSubjectsStore } from '@/stores/subjects'
import { useAuthStore } from '@/stores/auth'
import { toast } from '@/composables/useToast'

const logsStore = useLogsStore()
const studentsStore = useStudentsStore()
const subjectsStore = useSubjectsStore()
const authStore = useAuthStore()

const reportType = ref<'summary' | 'detailed'>('summary')
const selectedStudentId = ref<string>('')
const generating = ref(false)

const activeStudents = computed(() => studentsStore.activeStudents)
const logs = computed(() => logsStore.logs)
const schoolYear = computed(() => authStore.effectiveSchoolYear)

// Calculate stats for summary
const stats = computed(() => {
  let filteredLogs = logs.value
  if (selectedStudentId.value) {
    filteredLogs = filteredLogs.filter(l => l.studentId === selectedStudentId.value)
  }
  
  const totalHours = filteredLogs.reduce((sum, log) => sum + log.hours, 0)
  const coreHours = filteredLogs.reduce((sum, log) => {
    const subject = subjectsStore.subjects.find(s => s.id === log.subjectId)
    return sum + (subject?.type === 'core' ? log.hours : 0)
  }, 0)
  const electiveHours = totalHours - coreHours
  
  return { totalHours, coreHours, electiveHours, logCount: filteredLogs.length }
})

function generateCSV() {
  generating.value = true
  
  try {
    let filteredLogs = logs.value
    if (selectedStudentId.value) {
      filteredLogs = filteredLogs.filter(l => l.studentId === selectedStudentId.value)
    }
    
    // Sort by date
    const sortedLogs = [...filteredLogs].sort((a, b) => a.date.localeCompare(b.date))
    
    // Build CSV
    const headers = ['Date', 'Student', 'Subject', 'Hours', 'Description', 'Location']
    const rows = sortedLogs.map(log => {
      const student = studentsStore.students.find(s => s.id === log.studentId)
      const subject = subjectsStore.subjects.find(s => s.id === log.subjectId)
      return [
        log.date.split('T')[0],
        student?.name || 'Unknown',
        subject?.name || 'Unknown',
        log.hours.toString(),
        `"${(log.description || '').replace(/"/g, '""')}"`,
        log.locationType
      ].join(',')
    })
    
    const csv = [headers.join(','), ...rows].join('\n')
    
    // Download
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `homeschool-logs-${schoolYear.value}.csv`
    link.click()
    URL.revokeObjectURL(url)
    
    toast.success('CSV exported successfully')
  } catch (e) {
    toast.error('Failed to export CSV')
  } finally {
    generating.value = false
  }
}

async function generatePDF() {
  generating.value = true
  
  try {
    // For now, we'll generate a simple HTML-based printable page
    // In production, you could use a library like jsPDF or a server-side PDF generator
    
    let filteredLogs = logs.value
    if (selectedStudentId.value) {
      filteredLogs = filteredLogs.filter(l => l.studentId === selectedStudentId.value)
    }
    
    const sortedLogs = [...filteredLogs].sort((a, b) => a.date.localeCompare(b.date))
    
    // Build printable HTML
    const html = buildPrintableHTML(sortedLogs)
    
    // Open in new window and trigger print
    const printWindow = window.open('', '_blank')
    if (printWindow) {
      printWindow.document.write(html)
      printWindow.document.close()
      printWindow.print()
    }
    
    toast.success('Print dialog opened')
  } catch (e) {
    toast.error('Failed to generate PDF')
  } finally {
    generating.value = false
  }
}

function buildPrintableHTML(sortedLogs: typeof logs.value) {
  const studentName = selectedStudentId.value 
    ? studentsStore.students.find(s => s.id === selectedStudentId.value)?.name || 'Unknown'
    : 'All Students'
  
  const title = reportType.value === 'summary' 
    ? `Hours Summary Report - ${schoolYear.value}`
    : `Detailed Log Report - ${schoolYear.value}`
  
  if (reportType.value === 'summary') {
    // Group by student and subject
    const byStudent: Record<string, Record<string, number>> = {}
    sortedLogs.forEach(log => {
      const student = studentsStore.students.find(s => s.id === log.studentId)
      const subject = subjectsStore.subjects.find(s => s.id === log.subjectId)
      const studentName = student?.name || 'Unknown'
      const subjectName = subject?.name || 'Unknown'
      
      if (!byStudent[studentName]) byStudent[studentName] = {}
      byStudent[studentName][subjectName] = (byStudent[studentName][subjectName] || 0) + log.hours
    })
    
    let tables = ''
    for (const [student, subjects] of Object.entries(byStudent)) {
      let rows = ''
      let total = 0
      for (const [subject, hours] of Object.entries(subjects)) {
        rows += `<tr><td>${subject}</td><td style="text-align:right">${hours.toFixed(2)}</td></tr>`
        total += hours
      }
      rows += `<tr style="font-weight:bold;border-top:2px solid #333"><td>Total</td><td style="text-align:right">${total.toFixed(2)}</td></tr>`
      tables += `<h3>${student}</h3><table border="1" cellpadding="8" style="border-collapse:collapse;width:100%"><tr style="background:#eee"><th>Subject</th><th>Hours</th></tr>${rows}</table><br/>`
    }
    
    return `
      <!DOCTYPE html>
      <html>
      <head><title>${title}</title><style>body{font-family:Arial,sans-serif;max-width:800px;margin:40px auto;padding:20px}h1{border-bottom:2px solid #333;padding-bottom:10px}table{margin:20px 0}</style></head>
      <body>
        <h1>${title}</h1>
        <p><strong>Family:</strong> ${authStore.family?.name || 'Unknown'}</p>
        <p><strong>Generated:</strong> ${new Date().toLocaleDateString()}</p>
        ${tables}
        <div style="margin-top:50px;border-top:1px solid #ccc;padding-top:20px">
          <p>I certify that the above hours are accurate:</p>
          <p style="margin-top:40px">Signature: _________________________________ Date: _____________</p>
        </div>
      </body>
      </html>
    `
  } else {
    // Detailed log table
    let rows = ''
    sortedLogs.forEach(log => {
      const student = studentsStore.students.find(s => s.id === log.studentId)
      const subject = subjectsStore.subjects.find(s => s.id === log.subjectId)
      rows += `<tr>
        <td>${log.date.split('T')[0]}</td>
        <td>${student?.name || 'Unknown'}</td>
        <td>${subject?.name || 'Unknown'}</td>
        <td style="text-align:right">${log.hours.toFixed(2)}</td>
        <td>${log.description || ''}</td>
      </tr>`
    })
    
    return `
      <!DOCTYPE html>
      <html>
      <head><title>${title}</title><style>body{font-family:Arial,sans-serif;max-width:900px;margin:40px auto;padding:20px}h1{border-bottom:2px solid #333;padding-bottom:10px}table{margin:20px 0;font-size:12px}</style></head>
      <body>
        <h1>${title}</h1>
        <p><strong>Family:</strong> ${authStore.family?.name || 'Unknown'}</p>
        <p><strong>Student:</strong> ${studentName}</p>
        <p><strong>Generated:</strong> ${new Date().toLocaleDateString()}</p>
        <p><strong>Total Entries:</strong> ${sortedLogs.length} | <strong>Total Hours:</strong> ${stats.value.totalHours.toFixed(2)}</p>
        <table border="1" cellpadding="8" style="border-collapse:collapse;width:100%">
          <tr style="background:#eee"><th>Date</th><th>Student</th><th>Subject</th><th>Hours</th><th>Description</th></tr>
          ${rows}
        </table>
        <div style="margin-top:50px;border-top:1px solid #ccc;padding-top:20px">
          <p>I certify that the above hours are accurate:</p>
          <p style="margin-top:40px">Signature: _________________________________ Date: _____________</p>
        </div>
      </body>
      </html>
    `
  }
}

onMounted(async () => {
  if (studentsStore.students.length === 0) {
    await studentsStore.fetchStudents()
  }
  if (subjectsStore.subjects.length === 0) {
    await subjectsStore.fetchSubjects()
  }
  if (logsStore.logs.length === 0) {
    await logsStore.fetchLogs({ schoolYear: authStore.effectiveSchoolYear })
  }
})
</script>

<template>
  <div class="max-w-2xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Export Data</h1>
        <p class="text-gray-600 mt-1">Generate reports for state compliance</p>
      </div>
      <router-link to="/settings" class="text-primary-600 hover:text-primary-700">
        ← Back to Settings
      </router-link>
    </div>

    <!-- Current Stats -->
    <div class="card mb-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Current Year Summary</h2>
      <div class="grid grid-cols-3 gap-4 text-center">
        <div class="bg-blue-50 rounded-lg p-4">
          <p class="text-2xl font-bold text-blue-600">{{ stats.totalHours.toFixed(1) }}</p>
          <p class="text-sm text-gray-600">Total Hours</p>
        </div>
        <div class="bg-green-50 rounded-lg p-4">
          <p class="text-2xl font-bold text-green-600">{{ stats.coreHours.toFixed(1) }}</p>
          <p class="text-sm text-gray-600">Core Hours</p>
        </div>
        <div class="bg-purple-50 rounded-lg p-4">
          <p class="text-2xl font-bold text-purple-600">{{ stats.electiveHours.toFixed(1) }}</p>
          <p class="text-sm text-gray-600">Elective Hours</p>
        </div>
      </div>
    </div>

    <!-- Export Options -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Export Options</h2>
      
      <div class="space-y-4">
        <!-- Report Type -->
        <div>
          <label class="label">Report Type</label>
          <div class="mt-2 flex gap-4">
            <label class="flex items-center cursor-pointer">
              <input 
                v-model="reportType" 
                type="radio" 
                value="summary" 
                class="mr-2"
              />
              <span>Hours Summary</span>
            </label>
            <label class="flex items-center cursor-pointer">
              <input 
                v-model="reportType" 
                type="radio" 
                value="detailed" 
                class="mr-2"
              />
              <span>Detailed Logs</span>
            </label>
          </div>
          <p class="text-xs text-gray-500 mt-1">
            {{ reportType === 'summary' 
              ? 'Per-student breakdown with total hours by subject'
              : 'Full table with every log entry'
            }}
          </p>
        </div>

        <!-- Student Filter -->
        <div>
          <label class="label">Filter by Student (optional)</label>
          <select v-model="selectedStudentId" class="mt-1 input">
            <option value="">All Students</option>
            <option 
              v-for="student in activeStudents" 
              :key="student.id" 
              :value="student.id"
            >
              {{ student.name }}
            </option>
          </select>
        </div>

        <!-- Export Buttons -->
        <div class="flex gap-4 pt-4 border-t border-gray-200">
          <button 
            class="btn-primary flex-1"
            :disabled="generating"
            @click="generatePDF"
          >
            <span class="mr-2">📄</span>
            {{ generating ? 'Generating...' : 'Print / PDF' }}
          </button>
          <button 
            class="btn-secondary flex-1"
            :disabled="generating"
            @click="generateCSV"
          >
            <span class="mr-2">📊</span>
            {{ generating ? 'Generating...' : 'Export CSV' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Info -->
    <div class="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
      <h3 class="text-sm font-medium text-blue-800 mb-2">💡 Tips</h3>
      <ul class="text-sm text-blue-700 list-disc list-inside space-y-1">
        <li>Use "Print / PDF" to generate a printable report (save as PDF from print dialog)</li>
        <li>Use "Export CSV" to download a spreadsheet-compatible file</li>
        <li>Reports include a signature line for certification</li>
      </ul>
    </div>
  </div>
</template>
