import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";

interface StandUpTestsProps {
  patientId: string;
}

const StandUpTests = ({ patientId }: StandUpTestsProps) => {
  const { data: tests, isLoading } = useQuery({
    queryKey: ["standup-tests", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("standup_tests")
        .select("*")
        .eq("patient_id", patientId)
        .order("test_date", { ascending: false });
      
      if (error) throw error;
      return data;
    },
  });

  const getSeverityColor = (severity: string | null) => {
    switch (severity?.toLowerCase()) {
      case "mild": return "bg-accent";
      case "moderate": return "bg-yellow-500";
      case "severe": return "bg-destructive";
      default: return "bg-muted";
    }
  };

  const getResultColor = (result: string | null) => {
    if (result?.toLowerCase().includes("positive")) return "text-destructive";
    if (result?.toLowerCase().includes("negative")) return "text-accent";
    return "text-muted-foreground";
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Stand-Up Test Results</CardTitle>
        <CardDescription>Postural orthostatic tachycardia assessment history</CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="text-center py-8 text-muted-foreground">Loading test results...</div>
        ) : tests && tests.length > 0 ? (
          <div className="space-y-4">
            {tests.map((test) => (
              <Card key={test.id} className="border-l-4" style={{ borderLeftColor: test.test_result?.includes("Positive") ? "hsl(var(--destructive))" : "hsl(var(--accent))" }}>
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="text-lg">
                        {format(new Date(test.test_date), "MMMM dd, yyyy")} at {test.test_time}
                      </CardTitle>
                      <CardDescription className={getResultColor(test.test_result)}>
                        {test.test_result || "Pending"}
                      </CardDescription>
                    </div>
                    {test.pots_severity && (
                      <Badge className={getSeverityColor(test.pots_severity)}>
                        {test.pots_severity}
                      </Badge>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">Supine HR</p>
                      <p className="text-lg font-semibold">{test.supine_hr || "N/A"} bpm</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">1min Standing HR</p>
                      <p className="text-lg font-semibold">{test.standing_1min_hr || "N/A"} bpm</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">3min Standing HR</p>
                      <p className="text-lg font-semibold">{test.standing_3min_hr || "N/A"} bpm</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">HR Increase (1min)</p>
                      <p className="text-lg font-semibold text-primary">
                        {test.hr_increase_1min ? `+${test.hr_increase_1min}` : "N/A"} bpm
                      </p>
                    </div>
                  </div>
                  {test.notes && (
                    <div className="mt-4 pt-4 border-t">
                      <p className="text-sm text-muted-foreground mb-1">Clinical Notes</p>
                      <p className="text-sm">{test.notes}</p>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">
            No stand-up test results available
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default StandUpTests;
