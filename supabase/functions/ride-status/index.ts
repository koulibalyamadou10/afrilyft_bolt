import { createClient } from 'npm:@supabase/supabase-js@2.39.7'
import { corsHeaders } from '../_shared/cors.ts'

interface RideStatusRequest {
  rideId: string
  status: 'pending' | 'searching' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'
  userId: string
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { rideId, status, userId }: RideStatusRequest = await req.json()

    if (!rideId || !status || !userId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: rideId, status, userId' }),
        {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
          status: 400,
        }
      )
    }

    // Get the ride to check permissions
    const { data: ride, error: rideError } = await supabaseClient
      .from('rides')
      .select('customer_id, driver_id, status')
      .eq('id', rideId)
      .single()

    if (rideError) {
      throw new Error(`Ride not found: ${rideError.message}`)
    }

    // Check permissions
    const isCustomer = ride.customer_id === userId
    const isDriver = ride.driver_id === userId
    
    if (!isCustomer && !isDriver) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: You are not associated with this ride' }),
        {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
          status: 403,
        }
      )
    }

    // Validate status transitions
    const validTransition = validateStatusTransition(ride.status, status, isCustomer, isDriver)
    if (!validTransition.valid) {
      return new Response(
        JSON.stringify({ error: `Invalid status transition: ${validTransition.message}` }),
        {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
          status: 400,
        }
      )
    }

    // Update the ride status
    const updateData: Record<string, any> = { status }
    
    // Add timestamp based on status
    if (status === 'accepted') updateData.accepted_at = new Date().toISOString()
    if (status === 'in_progress') updateData.started_at = new Date().toISOString()
    if (status === 'completed') updateData.completed_at = new Date().toISOString()
    if (status === 'cancelled') updateData.cancelled_at = new Date().toISOString()

    const { error: updateError } = await supabaseClient
      .from('rides')
      .update(updateData)
      .eq('id', rideId)

    if (updateError) {
      throw updateError
    }

    // Create notification for the other party
    const notificationUserId = isCustomer ? ride.driver_id : ride.customer_id
    
    if (notificationUserId) {
      let title = ''
      let message = ''
      
      switch (status) {
        case 'accepted':
          title = 'Trajet accepté'
          message = 'Un chauffeur a accepté votre demande de trajet'
          break
        case 'in_progress':
          title = 'Trajet démarré'
          message = 'Votre trajet a commencé'
          break
        case 'completed':
          title = 'Trajet terminé'
          message = 'Votre trajet est terminé'
          break
        case 'cancelled':
          title = 'Trajet annulé'
          message = isCustomer ? 'Le client a annulé le trajet' : 'Le chauffeur a annulé le trajet'
          break
      }
      
      if (title && message) {
        await supabaseClient
          .from('notifications')
          .insert({
            user_id: notificationUserId,
            title,
            message,
            type: 'ride_update',
            data: { ride_id: rideId, status },
          })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Ride status updated to ${status}`,
        ride_id: rideId
      }),
      {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in ride-status function:', error)
    
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

function validateStatusTransition(
  currentStatus: string, 
  newStatus: string, 
  isCustomer: boolean, 
  isDriver: boolean
): { valid: boolean, message: string } {
  // Define valid transitions
  const validTransitions: Record<string, string[]> = {
    'pending': ['searching', 'cancelled'],
    'searching': ['accepted', 'cancelled'],
    'accepted': ['in_progress', 'cancelled'],
    'in_progress': ['completed', 'cancelled'],
    'completed': [],
    'cancelled': [],
  }

  // Check if the transition is valid
  if (!validTransitions[currentStatus]?.includes(newStatus)) {
    return { 
      valid: false, 
      message: `Cannot transition from ${currentStatus} to ${newStatus}` 
    }
  }

  // Check permissions for specific transitions
  if (newStatus === 'accepted' && !isDriver) {
    return { valid: false, message: 'Only drivers can accept rides' }
  }
  
  if (newStatus === 'in_progress' && !isDriver) {
    return { valid: false, message: 'Only drivers can start rides' }
  }
  
  if (newStatus === 'completed' && !isDriver) {
    return { valid: false, message: 'Only drivers can complete rides' }
  }

  return { valid: true, message: '' }
}