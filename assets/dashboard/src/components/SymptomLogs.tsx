import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";

interface SymptomLogsProps {
  patientId: string;
}

const SymptomLogs = ({ patientId }: SymptomLogsProps) => {
  const { data: logs, isLoading } = useQuery({
    queryKey: ["symptom-logs", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("symptom_logs")
        .select("*")
        .eq("patient_id", patientId)
        .order("timestamp", { ascending: false })
        .limit(50);
      
      if (error) throw error;
      return data;
    },
  });

  const getSeverityColor = (severity: number) => {
    if (severity >= 8) return "bg-destructive";
    if (severity >= 5) return "bg-yellow-500";
    return "bg-accent";
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Symptom Logs</CardTitle>
        <CardDescription>Patient-reported symptoms and severity ratings</CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="text-center py-8 text-muted-foreground">Loading symptom logs...</div>
        ) : logs && logs.length > 0 ? (
          <div className="space-y-4">
            {logs.map((log) => (
              <Card key={log.id}>
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="text-lg">
                        {format(new Date(log.timestamp), "MMM dd, yyyy 'at' h:mm a")}
                      </CardTitle>
                      {log.activity_type && (
                        <CardDescription>During: {log.activity_type}</CardDescription>
                      )}
                    </div>
                    <Badge className={getSeverityColor(log.severity)}>
                      Severity: {log.severity}/10
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    <div>
                      <p className="text-sm text-muted-foreground mb-2">Symptoms:</p>
                      <div className="flex flex-wrap gap-2">
                        {log.symptoms.map((symptom, idx) => (
                          <Badge key={idx} variant="outline">
                            {symptom}
                          </Badge>
                        ))}
                      </div>
                    </div>
                    {log.other_details && (
                      <div className="mt-3 pt-3 border-t">
                        <p className="text-sm text-muted-foreground mb-1">Additional Details:</p>
                        <p className="text-sm">{log.other_details}</p>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">
            No symptom logs available
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default SymptomLogs;
