import { createClient } from 'npm:@supabase/supabase-js@2.39.7'
import { corsHeaders } from '../_shared/cors.ts'

interface NotificationRequest {
  userId: string
  title: string
  message: string
  type: 'ride_request' | 'ride_update' | 'payment' | 'general'
  data?: Record<string, any>
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { userId, title, message, type, data }: NotificationRequest = await req.json()

    if (!userId || !title || !message || !type) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: userId, title, message, type' }),
        {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
          status: 400,
        }
      )
    }

    // Insert notification into database
    const { data: notification, error } = await supabaseClient
      .from('notifications')
      .insert({
        user_id: userId,
        title,
        message,
        type,
        data: data || null,
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    // Here you could add push notification logic using services like:
    // - Firebase Cloud Messaging (FCM)
    // - Apple Push Notification Service (APNs)
    // - OneSignal, etc.

    return new Response(
      JSON.stringify({
        success: true,
        notification,
        message: 'Notification sent successfully'
      }),
      {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in notifications function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
        status: 500,
      }
    )
  }
})