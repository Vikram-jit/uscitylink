import axios from 'axios'
import dotenv from 'dotenv'

dotenv.config()

const axiosInstance = axios.create({
  baseURL: `${'https://api.textrequest.com/api/v3/'}`,
  timeout: 5000,
  headers: {
    'x-api-key': process.env.TEXT_REQUEST_API_KEY,
  }
})

export const fetchData = async (endpoint: string, options = {}) => {
  try {
    const response = await axiosInstance(`${endpoint}`, options)

    return response.data
  } catch (error) {
    console.error('Error retrieving data:', error)
    throw new Error('Could not get data')
  }
}

export const postMethod = async (endpoint: string, data: any, options = {},ignoreError = false) => {
  try {
    const response = await axiosInstance.post(endpoint, data, options)

    return response.data
  } catch (error: any) {
    if(!ignoreError){
      throw new Error(error?.response?.data?.message || 'Unknown Error')
    }

  }
}

export const deleteMethod = async (endpoint: string, options = {}) => {
  try {
    const response = await axiosInstance.delete(endpoint, options)

    return response.data
  } catch (error: any) {
    throw new Error(error?.response?.data?.message || 'Unknown Error')
  }
}

export const putMethod = async (endpoint: string, options = {}) => {
  try {
    const response = await axiosInstance.put(endpoint, options)

    return response.data
  } catch (error: any) {
    throw new Error(error?.response?.data?.message || 'Unknown Error')
  }
}