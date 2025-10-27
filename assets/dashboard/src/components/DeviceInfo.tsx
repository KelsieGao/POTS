import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Battery, Wifi, AlertCircle } from "lucide-react";
import { format } from "date-fns";

interface DeviceInfoProps {
  patientId: string;
}

const DeviceInfo = ({ patientId }: DeviceInfoProps) => {
  const { data: devices, isLoading } = useQuery({
    queryKey: ["devices", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("devices")
        .select("*")
        .eq("patient_id", patientId)
        .order("last_sync", { ascending: false });
      
      if (error) throw error;
      return data;
    },
  });

  const getBatteryColor = (level: number | null) => {
    if (!level) return "text-muted-foreground";
    if (level < 20) return "text-destructive";
    if (level < 50) return "text-yellow-500";
    return "text-accent";
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Connected Devices</CardTitle>
        <CardDescription>Wearable devices and monitoring equipment</CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="text-center py-8 text-muted-foreground">Loading device information...</div>
        ) : devices && devices.length > 0 ? (
          <div className="space-y-4">
            {devices.map((device) => (
              <Card key={device.id} className={!device.is_active ? "opacity-60" : ""}>
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="text-lg">
                        {device.device_name || device.device_id}
                      </CardTitle>
                      <CardDescription>
                        {device.device_type || "Unknown Type"}
                        {device.firmware_version && ` • v${device.firmware_version}`}
                      </CardDescription>
                    </div>
                    <Badge variant={device.is_active ? "default" : "secondary"}>
                      {device.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="flex items-center gap-2">
                      <Battery className={`h-5 w-5 ${getBatteryColor(device.battery_level)}`} />
                      <div>
                        <p className="text-sm text-muted-foreground">Battery</p>
                        <p className="text-lg font-semibold">
                          {device.battery_level !== null ? `${device.battery_level}%` : "N/A"}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Wifi className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <p className="text-sm text-muted-foreground">Last Sync</p>
                        <p className="text-sm font-medium">
                          {device.last_sync 
                            ? format(new Date(device.last_sync), "MMM dd, HH:mm")
                            : "Never"}
                        </p>
                      </div>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Recording Hours</p>
                      <p className="text-lg font-semibold">
                        {device.total_recording_hours || 0}h
                      </p>
                    </div>
                    {device.last_maintenance_date && (
                      <div className="flex items-center gap-2">
                        <AlertCircle className="h-5 w-5 text-muted-foreground" />
                        <div>
                          <p className="text-sm text-muted-foreground">Last Maintenance</p>
                          <p className="text-sm font-medium">
                            {format(new Date(device.last_maintenance_date), "MMM dd, yyyy")}
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">
            No devices connected
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default DeviceInfo;
