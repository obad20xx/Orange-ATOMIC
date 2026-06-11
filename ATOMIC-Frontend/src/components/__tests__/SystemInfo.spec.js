import { mount, flushPromises } from '@vue/test-utils'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import SystemInfo from '../SystemInfo.vue'

vi.mock('../../services/api', () => ({
  getSystemInfos: vi.fn(),
}))

import { getSystemInfos } from '../../services/api'

describe('SystemInfo.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows loading spinner initially', () => {
    getSystemInfos.mockReturnValue(new Promise(() => {}))
    const wrapper = mount(SystemInfo)
    expect(wrapper.find('.banner--loading').exists()).toBe(true)
  })

  it('renders success banner with vault version on success', async () => {
    getSystemInfos.mockResolvedValue({
      version: '1.15.0',
      cluster_name: 'atomic-cluster',
      service_unavailable: false,
    })
    const wrapper = mount(SystemInfo)
    await flushPromises()
    expect(wrapper.find('.banner--loading').exists()).toBe(false)
    expect(wrapper.find('.banner--success').exists()).toBe(true)
    expect(wrapper.find('.banner--success').text()).toContain('1.15.0')
  })

  it('renders amber warning when vault is unavailable', async () => {
    getSystemInfos.mockResolvedValue({ service_unavailable: true })
    const wrapper = mount(SystemInfo)
    await flushPromises()
    expect(wrapper.find('.banner--warning').exists()).toBe(true)
  })

  it('renders error banner when API call fails', async () => {
    getSystemInfos.mockRejectedValue(new Error('Network Error'))
    const wrapper = mount(SystemInfo)
    await flushPromises()
    expect(wrapper.find('.banner--error').exists()).toBe(true)
    expect(wrapper.find('.banner--error').text()).toContain('Network Error')
  })
})
