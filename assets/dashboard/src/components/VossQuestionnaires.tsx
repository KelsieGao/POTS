import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface VossQuestionnairesProps {
  patientId: string;
}

const VossQuestionnaires = ({ patientId }: VossQuestionnairesProps) => {
  const { data: questionnaires, isLoading } = useQuery({
    queryKey: ["voss-questionnaires", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("voss_questionnaires")
        .select("*")
        .eq("patient_id", patientId)
        .order("completed_at", { ascending: false });
      
      if (error) throw error;
      return data;
    },
  });

  const getSeverityBadge = (score: number | null) => {
    if (!score) return <Badge variant="outline">Not scored</Badge>;
    if (score >= 7) return <Badge variant="destructive">Severe</Badge>;
    if (score >= 4) return <Badge className="bg-orange-500">Moderate</Badge>;
    return <Badge className="bg-green-500">Mild</Badge>;
  };

  if (isLoading) {
    return (
      <Card>
        <CardContent className="py-8">
          <div className="text-center text-muted-foreground">Loading questionnaires...</div>
        </CardContent>
      </Card>
    );
  }

  if (!questionnaires || questionnaires.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>VOSS Questionnaires</CardTitle>
          <CardDescription>Vanderbilt Orthostatic Symptom Score assessments</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-center text-muted-foreground py-8">
            No questionnaire data available yet
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {questionnaires.map((questionnaire) => (
        <Card key={questionnaire.id}>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-xl">
                  {new Date(questionnaire.completed_at).toLocaleDateString()}
                </CardTitle>
                <CardDescription>
                  Completed at {new Date(questionnaire.completed_at).toLocaleTimeString()}
                </CardDescription>
              </div>
              {questionnaire.total_score && (
                <div className="text-right">
                  <div className="text-2xl font-bold">{questionnaire.total_score}</div>
                  <div className="text-sm text-muted-foreground">Total Score</div>
                  {getSeverityBadge(questionnaire.total_score)}
                </div>
              )}
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {questionnaire.dizziness_frequency !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Dizziness Frequency</p>
                  <p className="text-lg font-semibold">{questionnaire.dizziness_frequency}</p>
                </div>
              )}
              {questionnaire.symptom_severity !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Symptom Severity</p>
                  <p className="text-lg font-semibold">{questionnaire.symptom_severity}</p>
                </div>
              )}
              {questionnaire.symptom_frequency !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Symptom Frequency</p>
                  <p className="text-lg font-semibold">{questionnaire.symptom_frequency}</p>
                </div>
              )}
              {questionnaire.orthostatic_intolerance !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Orthostatic Intolerance</p>
                  <p className="text-lg font-semibold">{questionnaire.orthostatic_intolerance}</p>
                </div>
              )}
              {questionnaire.fatigue_level !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Fatigue Level</p>
                  <p className="text-lg font-semibold">{questionnaire.fatigue_level}</p>
                </div>
              )}
              {questionnaire.cognitive_symptoms !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Cognitive Symptoms</p>
                  <p className="text-lg font-semibold">{questionnaire.cognitive_symptoms}</p>
                </div>
              )}
              {questionnaire.sleep_quality !== null && (
                <div>
                  <p className="text-sm text-muted-foreground">Sleep Quality</p>
                  <p className="text-lg font-semibold">{questionnaire.sleep_quality}</p>
                </div>
              )}
            </div>
            {questionnaire.interpretation && (
              <div className="mt-4 pt-4 border-t">
                <p className="text-sm text-muted-foreground mb-2">Interpretation</p>
                <p className="text-base">{questionnaire.interpretation}</p>
              </div>
            )}
            {questionnaire.notes && (
              <div className="mt-4">
                <p className="text-sm text-muted-foreground mb-2">Notes</p>
                <p className="text-base">{questionnaire.notes}</p>
              </div>
            )}
          </CardContent>
        </Card>
      ))}
    </div>
  );
};

export default VossQuestionnaires;
